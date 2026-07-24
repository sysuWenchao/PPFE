#include "utils.h"
<<<<<<< HEAD
#include <cmath>
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
	// Box-Muller with 53-bit uniform inputs sourced from the OS-backed CSPRNG.
	// u1 is in (0, 1] to keep log(u1) finite.
	constexpr double kTwoPi = 6.283185307179586476925286766559;
	const double u1 = 1.0 - SecureUnitInterval53();
	const double u2 = SecureUnitInterval53();
	const double standard_normal =
		std::sqrt(-2.0 * std::log(u1)) * std::cos(kTwoPi * u2);
	return static_cast<int64_t>(
		std::llround(standard_normal * ANSWER_NOISE_SIGMA));
}
=======
>>>>>>> origin/main

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
<<<<<<< HEAD
	for (uint64_t i = 0; i < DBSizeInUint64; i++) {
=======
	/*ifstream frand("/dev/urandom"); 
	frand.read((char*) *DB, DBSizeInUint64);
	frand.close();*/
	 for (uint64_t i = 0; i < DBSizeInUint64; i++) {
>>>>>>> origin/main
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
<<<<<<< HEAD
}
=======
}
>>>>>>> origin/main
