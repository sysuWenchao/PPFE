#include "utils.h"

#include <cmath>
#include <cstdint>
#include <iostream>
#include <stdexcept>

namespace
{
void Require(bool condition, const char *message)
{
    if (!condition)
        throw std::runtime_error(message);
}
}

int main()
{
    static_assert(PPFE_COEFF_MODULUS_BITS == 54);
    static_assert(PPFE_PLAIN_MODULUS_BITS == 20);
    static_assert(PPFE_ANSWER_NOISE_SIGMA_BITS == 22);
    static_assert(PPFE_ANSWER_NOISE_SIGMA == (uint64_t{1} << 22));

    Require(SelectPolyModulusDegree(10) == 2048,
            "unexpected degree for 2^10 database");
    Require(SelectPolyModulusDegree(22) == 2048,
            "unexpected degree for 2^22 database");
    Require(SelectPolyModulusDegree(24) == 4096,
            "unexpected degree for 2^24 database");

    const uint64_t representative_q = (uint64_t{1} << 53) + 1;
    const uint64_t representative_p = (uint64_t{1} << 19) + 1;
    ValidateProtocolParameters(PPFE_COEFF_MODULUS_BITS,
                               PPFE_PLAIN_MODULUS_BITS,
                               representative_q, representative_p);

    bool rejected_bad_parameters = false;
    try
    {
        ValidateProtocolParameters(53, PPFE_PLAIN_MODULUS_BITS,
                                   representative_q, representative_p);
    }
    catch (const std::invalid_argument &)
    {
        rejected_bad_parameters = true;
    }
    Require(rejected_bad_parameters, "mismatched parameters were accepted");

    Require(AddSignedMod(3, -5, 11) == 9,
            "negative answer noise is reduced incorrectly");
    Require(AddSignedMod(10, 5, 11) == 4,
            "positive answer noise is reduced incorrectly");

    const std::string key1 = GeneratePrfKey();
    const std::string key2 = GeneratePrfKey();
    Require(key1.size() == CryptoPP::AES::DEFAULT_KEYLENGTH,
            "PRF key has the wrong size");
    Require(key1 != key2, "independent PRF keys unexpectedly match");

    const uint64_t mask_modulus = (uint64_t{1} << 54) - 33;
    bool observed_value_above_legacy_rand = false;
    for (size_t i = 0; i < 128; ++i)
    {
        const uint64_t sample = SecureRandomUint64Below(mask_modulus);
        Require(sample < mask_modulus, "mask is outside Z_q");
        observed_value_above_legacy_rand |= sample > 0x7fffffffULL;
    }
    Require(observed_value_above_legacy_rand,
            "mask sampler appears limited to the legacy rand() range");

    bool saw_zero = false;
    bool saw_one = false;
    for (size_t i = 0; i < 256; ++i)
    {
        if (SecureRandomBit())
            saw_one = true;
        else
            saw_zero = true;
    }
    Require(saw_zero && saw_one, "secure random bit sampler is degenerate");

    constexpr size_t kNoiseSamples = 8192;
    long double sum = 0;
    long double sum_squares = 0;
    for (size_t i = 0; i < kNoiseSamples; ++i)
    {
        const long double sample = SampleAnswerNoise();
        sum += sample;
        sum_squares += sample * sample;
    }
    const long double mean = sum / kNoiseSamples;
    const long double variance =
        sum_squares / kNoiseSamples - mean * mean;
    const long double sigma = std::sqrt(variance);
    const long double expected_sigma = PPFE_ANSWER_NOISE_SIGMA;
    Require(std::fabs(mean) < expected_sigma * 0.10L,
            "answer-noise mean is unexpectedly far from zero");
    Require(sigma > expected_sigma * 0.85L &&
                sigma < expected_sigma * 1.15L,
            "answer-noise sigma does not match Table 2");

    std::cout << "Security parameter and randomness checks passed\n";
    return 0;
}
