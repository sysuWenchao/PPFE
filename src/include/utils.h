#pragma once
#include "cryptopp/cryptlib.h"
#include "cryptopp/hex.h"
#include "cryptopp/rijndael.h"
#include "cryptopp/modes.h"
#include "cryptopp/files.h"
#include "cryptopp/osrng.h"
#include <cassert>
#include <cstdint>
#include <stdexcept>
#include <string>

#define LAMBDA 30

// Protocol parameters from Table 2. Keeping these values in one place prevents
// the client, server, tests, and documentation from silently diverging.
constexpr uint32_t PPFE_COEFF_MODULUS_BITS = 54;
constexpr uint32_t PPFE_PLAIN_MODULUS_BITS = 20;
constexpr uint32_t PPFE_ANSWER_NOISE_SIGMA_BITS = 22;
constexpr uint64_t PPFE_ANSWER_NOISE_SIGMA =
    uint64_t{1} << PPFE_ANSWER_NOISE_SIGMA_BITS;
constexpr uint32_t PPFE_MIN_POLY_MODULUS_DEGREE = 2048;
constexpr uint32_t PPFE_MAX_POLY_MODULUS_DEGREE = 32768;

static_assert(PPFE_ANSWER_NOISE_SIGMA_BITS < PPFE_COEFF_MODULUS_BITS,
              "answer noise must fit in the ciphertext modulus");

using namespace std;
using namespace CryptoPP;

// OS-backed cryptographic randomness. SecureRandomUint64Below uses rejection
// sampling, so every value in [0, upper_bound) has the same probability.
std::string GeneratePrfKey();
uint64_t SecureRandomUint64();
uint64_t SecureRandomUint64Below(uint64_t upper_bound);
bool SecureRandomBit();
int64_t SampleAnswerNoise();
uint64_t AddSignedMod(uint64_t value, int64_t delta, uint64_t modulus);

// Throws std::invalid_argument when runtime HE parameters do not match the
// protocol constants above.
void ValidateProtocolParameters(uint32_t coeff_modulus_bits,
                                uint32_t plain_modulus_bits,
                                uint64_t coeff_modulus,
                                uint64_t plain_modulus);
uint32_t SelectPolyModulusDegree(uint32_t log_db_size);
void ValidatePolyModulusDegree(uint32_t log_db_size,
                               uint32_t poly_modulus_degree);

// PRF across partition ID. 
// A single PRF call generates the values of v for 4 consecutive partition numbers for a single hintID and the values of r for 8 consecutive partition numbers for a single hintID, packed in 128 bits.
class PRFPartitionID{
  public:
  PRFPartitionID(string keyStr){
    assert(keyStr.size() == 16);
    SecByteBlock aesKey(reinterpret_cast<const CryptoPP::byte*>(keyStr.data()), AES::DEFAULT_KEYLENGTH);
    enc_.SetKey(aesKey, aesKey.size());
  }
  void evaluate(uint8_t *out, uint32_t word1, uint32_t word2, uint32_t word3){
    uint32_t prfIn [4] = {word1, (word3 << 16) | word2};
    enc_.ProcessBlock(
        reinterpret_cast<const CryptoPP::byte *>(prfIn),
        reinterpret_cast<CryptoPP::byte *>(out));
  }

  // Returns an indicator bit given a partition number, hint ID, and cutoff value for the hintID.
  bool PRF4Select(uint32_t hintID, uint32_t partID, uint32_t cutoff) {
    uint32_t ctxt [4];
    evaluate((uint8_t*) ctxt, hintID, partID / 4, 1);		
    return ctxt[partID % 4] < cutoff;	 
  }

  // Returns a partition offset given a partition number and hint ID 
  uint16_t PRF4Idx(uint32_t hintID, uint32_t partID) {
    uint16_t ctxt [8];
    evaluate((uint8_t*) ctxt, hintID, partID / 8, 2);	
    return ctxt[partID % 8];	
  }

  // Generate the partition offsets for the batch of 8 consecutive partitions that includes the given partID
  void PRFBatchIdx(uint16_t* prfIndices, uint32_t hintID, uint32_t partID) {
    evaluate((uint8_t*)prfIndices, hintID, partID / 8, 2);
  }

  // Generate the select values for the batch of 4 consecutive partitions that includes the given partID
  void PRFBatchSelect(uint32_t* prfSelectVals, uint32_t hintID, uint32_t partID) {
    evaluate((uint8_t *)prfSelectVals, hintID, partID / 4, 1);
  }

  private:
  // One AES-128 block is used directly as the PRF; no ECB message mode.
	AES::Encryption enc_;
};


// PRF across hint ID
// A single PRF call generates the values of v for 4 consecutive hintIDs for a single partition number and the values of r for 8 consecutive hintIDs for a single partition number, packed in 128 bits.
class PRFHintID{
  public:
  PRFHintID(string keyStr){
    assert(keyStr.size() == 16);
    SecByteBlock aesKey(reinterpret_cast<const CryptoPP::byte*>(keyStr.data()), AES::DEFAULT_KEYLENGTH);
    enc_.SetKey(aesKey, aesKey.size());
  }
  void evaluate(uint8_t *out, uint32_t word1, uint32_t word2, uint32_t word3){
    uint32_t prfIn [4] = {word1, (word3 << 16) | word2};
    enc_.ProcessBlock(
        reinterpret_cast<const CryptoPP::byte *>(prfIn),
        reinterpret_cast<CryptoPP::byte *>(out));
  }

  // Returns an indicator bit given a partition number, hint ID, and cutoff value for the hintID.
  bool PRF4Select(uint32_t hintID, uint32_t partID, uint32_t cutoff)
  {
    uint32_t ctxt[4];
    evaluate((uint8_t*) ctxt, hintID / 4, partID, 1);		
    return (ctxt[hintID % 4] < cutoff); 
  }

  // Returns a partition offset given a partition number and hint ID 
  uint16_t PRF4Idx(uint32_t hintID, uint32_t partID)
  {
    uint16_t ctxt [8];
    evaluate((uint8_t*) ctxt, hintID / 8, partID, 2);	
    return ctxt[hintID % 8];	
  }


  private:
  // One AES-128 block is used directly as the PRF; no ECB message mode.
	AES::Encryption enc_;
};


// Reads an entry from a DB into result.
void getEntryFromDB(uint64_t* DB, uint32_t index, uint64_t *result, uint32_t EntrySize);

// Initializes a database with random values.
void initDatabase(uint64_t** DB, uint64_t kLogDBSize, uint64_t kEntrySize, uint64_t plainModulus);

/* Given an array of PartNum prf values, finds the median value. May return 0 if algorithm does not find a median */
uint32_t FindCutoff(uint32_t *prfVals, uint32_t PartNum);
