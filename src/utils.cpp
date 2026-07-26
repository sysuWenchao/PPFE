#include "utils.h"
#include <algorithm>
#include <cmath>
#include <cstring>
#include <limits>
#include <stdexcept>

namespace
{
thread_local CryptoPP::AutoSeededRandomPool secure_rng;

double SecureUnitInterval53()
{
	uint64_t value = SecureRandomUint64() >> 11;
	return static_cast<double>(value) * (1.0 / 9007199254740992.0);
}

uint32_t BitLength(uint64_t value)
{
	uint32_t bits = 0;
	while (value != 0)
	{
		++bits;
		value >>= 1;
	}
	return bits;
}
}

std::string GeneratePrfKey()
{
	std::string key(CryptoPP::AES::DEFAULT_KEYLENGTH, '\0');
	secure_rng.GenerateBlock(
		reinterpret_cast<CryptoPP::byte *>(&key[0]), key.size());
	return key;
}

uint64_t SecureRandomUint64()
{
	uint64_t value = 0;
	secure_rng.GenerateBlock(
		reinterpret_cast<CryptoPP::byte *>(&value), sizeof(value));
	return value;
}

uint64_t SecureRandomUint64Below(uint64_t upper_bound)
{
	if (upper_bound == 0)
		throw std::invalid_argument("upper_bound must be positive");

	// 2^64 mod upper_bound. Rejecting the short prefix makes the remaining
	// interval an exact multiple of upper_bound.
	const uint64_t rejection_threshold = -upper_bound % upper_bound;
	uint64_t value;
	do
	{
		value = SecureRandomUint64();
	} while (value < rejection_threshold);
	return value % upper_bound;
}

bool SecureRandomBit()
{
	return static_cast<bool>(SecureRandomUint64() & 1);
}

int64_t SampleAnswerNoise()
{
	// Rounded continuous Gaussian sampling for the integer-valued answer noise.
	// Both uniforms contain 53 random bits from the OS-backed CSPRNG. Keeping u1
	// in (0, 1] avoids log(0).
	constexpr double kTwoPi = 6.283185307179586476925286766559;
	const double u1 = 1.0 - SecureUnitInterval53();
	const double u2 = SecureUnitInterval53();
	const double standard_normal =
		std::sqrt(-2.0 * std::log(u1)) * std::cos(kTwoPi * u2);
	return static_cast<int64_t>(std::llround(
		standard_normal * static_cast<double>(PPFE_ANSWER_NOISE_SIGMA)));
}

uint64_t AddSignedMod(uint64_t value, int64_t delta, uint64_t modulus)
{
	if (modulus == 0)
		throw std::invalid_argument("modulus must be positive");

	value %= modulus;
	if (delta >= 0)
	{
		const uint64_t addend = static_cast<uint64_t>(delta) % modulus;
		return addend >= modulus - value
			? addend - (modulus - value)
			: value + addend;
	}

	// This form is defined even for INT64_MIN.
	const uint64_t magnitude =
		static_cast<uint64_t>(-(delta + 1)) + 1;
	const uint64_t subtrahend = magnitude % modulus;
	return value >= subtrahend
		? value - subtrahend
		: modulus - (subtrahend - value);
}

void ValidateProtocolParameters(uint32_t coeff_modulus_bits,
								uint32_t plain_modulus_bits,
								uint64_t coeff_modulus,
								uint64_t plain_modulus)
{
	if (coeff_modulus_bits != PPFE_COEFF_MODULUS_BITS ||
		plain_modulus_bits != PPFE_PLAIN_MODULUS_BITS)
	{
		throw std::invalid_argument(
			"configured HE modulus bit sizes do not match PPFE Table 2");
	}
	if (BitLength(coeff_modulus) != PPFE_COEFF_MODULUS_BITS ||
		BitLength(plain_modulus) != PPFE_PLAIN_MODULUS_BITS)
	{
		throw std::invalid_argument(
			"generated HE moduli do not have the configured bit sizes");
	}
	if (plain_modulus >= coeff_modulus)
		throw std::invalid_argument(
			"plaintext modulus must be smaller than ciphertext modulus");
	if (PPFE_ANSWER_NOISE_SIGMA >= coeff_modulus)
		throw std::invalid_argument(
			"answer-noise sigma must fit in the ciphertext modulus");
}

uint32_t SelectPolyModulusDegree(uint32_t log_db_size)
{
	if (log_db_size >= 32)
		throw std::invalid_argument("Log2DBSize must be smaller than 32");

	const uint32_t part_size =
		uint32_t{1} << (log_db_size / 2 + log_db_size % 2);
	uint32_t degree = PPFE_MIN_POLY_MODULUS_DEGREE;
	while (degree < part_size && degree < PPFE_MAX_POLY_MODULUS_DEGREE)
		degree <<= 1;
	if (degree < part_size)
		throw std::invalid_argument(
			"database partition exceeds maximum polynomial degree");
	return degree;
}

void ValidatePolyModulusDegree(uint32_t log_db_size,
							   uint32_t poly_modulus_degree)
{
	if (poly_modulus_degree != SelectPolyModulusDegree(log_db_size))
		throw std::invalid_argument(
			"polynomial degree does not match the PPFE database partition");
}

void getEntryFromDB(uint64_t* DB, uint32_t index, uint64_t *result, uint32_t EntrySize)
{
#ifdef DEBUG
	uint64_t dummyData = index;
	dummyData <<= 1;
	for (uint32_t l = 0; l < EntrySize / 8; l++)
		result[l] = dummyData + l; 
	return;
#endif

	#ifdef SimLargeServer
		memcpy(result, ((uint8_t*) DB) + index, EntrySize);	
	#else
		memcpy(result, DB + index * (EntrySize / 8), EntrySize); 
	#endif	
};

void initDatabase(uint64_t** DB, uint64_t kLogDBSize, uint64_t kEntrySize, uint64_t plainModulus){
#ifdef SimLargeServer
	uint64_t DBSizeInUint64 = ((uint64_t) 1 << (kLogDBSize-3)) + kEntrySize;		
#else
	uint64_t DBSizeInUint64 = ((uint64_t) kEntrySize / 8) << kLogDBSize;
#endif	
	*DB = new uint64_t [DBSizeInUint64];
	for (uint64_t i = 0; i < DBSizeInUint64; i++) {
        (*DB)[i] = (999999999999+i) % plainModulus;
    }
}

uint32_t FindCutoff(uint32_t *prfVals, uint32_t PartNum) {
	uint32_t LowerFilter = 0x80000000 - (1 << 28);
	uint32_t UpperFilter = 0x80000000 + (1 << 28);

	uint32_t LowerCnt = 0, UpperCnt = 0, MiddleCnt = 0;	
	for (uint32_t k = 0; k < PartNum; k++)
  	{
		if (prfVals[k] < LowerFilter)
			LowerCnt++;
		else if (prfVals[k] > UpperFilter)
			UpperCnt++;
		else
		{
			prfVals[MiddleCnt] = prfVals[k];	// move to beginning, ok to overwrite filtered stuff
			MiddleCnt++;
		} 	
	}
	if (LowerCnt >= PartNum / 2 || UpperCnt >= PartNum / 2)
	{
	// cout << "Filtered too much" << endl;
		return 0;	// filtered too many, just give up this hint	

	}

	uint32_t *median = prfVals + PartNum / 2 - LowerCnt;
	nth_element(prfVals, median, prfVals + MiddleCnt);
	uint32_t cutoff = *median;
	*median = 0;
	for (uint32_t k = 0; k < MiddleCnt; k++){
		if (prfVals[k] == cutoff) return 0;
	}
	return cutoff;
}
