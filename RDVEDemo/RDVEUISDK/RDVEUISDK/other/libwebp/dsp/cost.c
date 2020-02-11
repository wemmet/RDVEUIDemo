// Copyright 2014 Google Inc. All Rights Reserved.
//
// Use of this source code is governed by a BSD-style license
// that can be found in the COPYING file in the root of the source
// tree. An additional intellectual property rights grant can be found
// in the file PATENTS. All contributing project authors may
// be found in the AUTHORS file in the root of the source tree.
// -----------------------------------------------------------------------------
//
// Author: Skal (pascal.massimino@gmail.com)

#include "./dsp.h"
#include "../enc/cost.h"

//------------------------------------------------------------------------------
// Boolean-cost cost table

const uint16_t VP8EntropyCost[256] = {
  1792, 1792, 1792, 1536, 1536, 1408, 1366, 1280, 1280, 1216,
  1178, 1152, 1110, 1076, 1061, 1024, 1024,  992,  968,  951,
   939,  911,  896,  878,  871,  854,  838,  820,  811,  794,
   786,  768,  768,  752,  740,  732,  720,  709,  704,  690,
   683,  672,  666,  655,  647,  640,  631,  622,  615,  607,
   598,  592,  586,  576,  572,  564,  559,  555,  547,  541,
   534,  528,  522,  512,  512,  504,  500,  494,  488,  483,
   477,  473,  467,  461,  458,  452,  448,  443,  438,  434,
   427,  424,  419,  415,  410,  406,  403,  399,  394,  390,
   384,  384,  377,  374,  370,  366,  362,  359,  355,  351,
   347,  342,  342,  336,  333,  330,  326,  323,  320,  316,
   312,  308,  305,  302,  299,  296,  293,  288,  287,  283,
   280,  277,  274,  272,  268,  266,  262,  256,  256,  256,
   251,  248,  245,  242,  240,  237,  234,  232,  228,  226,
   223,  221,  218,  216,  214,  211,  208,  205,  203,  201,
   198,  196,  192,  191,  188,  187,  183,  181,  179,  176,
   175,  171,  171,  168,  165,  163,  160,  159,  156,  154,
   152,  150,  148,  146,  144,  142,  139,  138,  135,  133,
   131,  128,  128,  125,  123,  121,  119,  117,  115,  113,
   111,  110,  107,  105,  103,  102,  100,   98,   96,   94,
    92,   91,   89,   86,   86,   83,   82,   80,   77,   76,
    74,   73,   71,   69,   67,   66,   64,   63,   61,   59,
    57,   55,   54,   52,   51,   49,   47,   46,   44,   43,
    41,   40,   38,   36,   35,   33,   32,   30,   29,   27,
    25,   24,   22,   21,   19,   18,   16,   15,   13,   12,
    10,    9,    7,    6,    4,    3
};

//------------------------------------------------------------------------------
// Level cost tables

// fixed costs for coding levels, deduce from the coding tree.
// This is only the part that doesn't depend on the probability state.
const uint16_t VP8LevelFixedCosts[MAX_LEVEL + 1] = {
     0,  256,  256,  256,  256,  432,  618,  630,
   731,  640,  640,  828,  901,  948, 1021, 1101,
  1174, 1221, 1294, 1042, 1085, 1115, 1158, 1202,
  1245, 1275, 1318, 1337, 1380, 1410, 1453, 1497,
  1540, 1570, 1613, 1280, 1295, 1317, 1332, 1358,
  1373, 1395, 1410, 1454, 1469, 1491, 1506, 1532,
  1547, 1569, 1584, 1601, 1616, 1638, 1653, 1679,
  1694, 1716, 1731, 1775, 1790, 1812, 1827, 1853,
  1868, 1890, 1905, 1727, 1733, 1742, 1748, 1759,
  1765, 1774, 1780, 1800, 1806, 1815, 1821, 1832,
  1838, 1847, 1853, 1878, 1884, 1893, 1899, 1910,
  1916, 1925, 1931, 1951, 1957, 1966, 1972, 1983,
  1989, 1998, 2004, 2027, 2033, 2042, 2048, 2059,
  2065, 2074, 2080, 2100, 2106, 2115, 2121, 2132,
  2138, 2147, 2153, 2178, 2184, 2193, 2199, 2210,
  2216, 2225, 2231, 2251, 2257, 2266, 2272, 2283,
  2289, 2298, 2304, 2168, 2174, 2183, 2189, 2200,
  2206, 2215, 2221, 2241, 2247, 2256, 2262, 2273,
  2279, 2288, 2294, 2319, 2325, 2334, 2340, 2351,
  2357, 2366, 2372, 2392, 2398, 2407, 2413, 2424,
  2430, 2439, 2445, 2468, 2474, 2483, 2489, 2500,
  2506, 2515, 2521, 2541, 2547, 2556, 2562, 2573,
  2579, 2588, 2594, 2619, 2625, 2634, 2640, 2651,
  2657, 2666, 2672, 2692, 2698, 2707, 2713, 2724,
  2730, 2739, 2745, 2540, 2546, 2555, 2561, 2572,
  2578, 2587, 2593, 2613, 2619, 2628, 2634, 2645,
  2651, 2660, 2666, 2691, 2697, 2706, 2712, 2723,
  2729, 2738, 2744, 2764, 2770, 2779, 2785, 2796,
  2802, 2811, 2817, 2840, 2846, 2855, 2861, 2872,
  2878, 2887, 2893, 2913, 2919, 2928, 2934, 2945,
  2951, 2960, 2966, 2991, 2997, 3006, 3012, 3023,
  3029, 3038, 3044, 3064, 3070, 3079, 3085, 3096,
  3102, 3111, 3117, 2981, 2987, 2996, 3002, 3013,
  3019, 3028, 3034, 3054, 3060, 3069, 3075, 3086,
  3092, 3101, 3107, 3132, 3138, 3147, 3153, 3164,
  3170, 3179, 3185, 3205, 3211, 3220, 3226, 3237,
  3243, 3252, 3258, 3281, 3287, 3296, 3302, 3313,
  3319, 3328, 3334, 3354, 3360, 3369, 3375, 3386,
  3392, 3401, 3407, 3432, 3438, 3447, 3453, 3464,
  3470, 3479, 3485, 3505, 3511, 3520, 3526, 3537,
  3543, 3552, 3558, 2816, 2822, 2831, 2837, 2848,
  2854, 2863, 2869, 2889, 2895, 2904, 2910, 2921,
  2927, 2936, 2942, 2967, 2973, 2982, 2988, 2999,
  3005, 3014, 3020, 3040, 3046, 3055, 3061, 3072,
  3078, 3087, 3093, 3116, 3122, 3131, 3137, 3148,
  3154, 3163, 3169, 3189, 3195, 3204, 3210, 3221,
  3227, 3236, 3242, 3267, 3273, 3282, 3288, 3299,
  3305, 3314, 3320, 3340, 3346, 3355, 3361, 3372,
  3378, 3387, 3393, 3257, 3263, 3272, 3278, 3289,
  3295, 3304, 3310, 3330, 3336, 3345, 3351, 3362,
  3368, 3377, 3383, 3408, 3414, 3423, 3429, 3440,
  3446, 3455, 3461, 3481, 3487, 3496, 3502, 3513,
  3519, 3528, 3534, 3557, 3563, 3572, 3578, 3589,
  3595, 3604, 3610, 3630, 3636, 3645, 3651, 3662,
  3668, 3677, 3683, 3708, 3714, 3723, 3729, 3740,
  3746, 3755, 3761, 3781, 3787, 3796, 3802, 3813,
  3819, 3828, 3834, 3629, 3635, 3644, 3650, 3661,
  3667, 3676, 3682, 3702, 3708, 3717, 3723, 3734,
  3740, 3749, 3755, 3780, 3786, 3795, 3801, 3812,
  3818, 3827, 3833, 3853, 3859, 3868, 3874, 3885,
  3891, 3900, 3906, 3929, 3935, 3944, 3950, 3961,
  3967, 3976, 3982, 4002, 4008, 4017, 4023, 4034,
  4040, 4049, 4055, 4080, 4086, 4095, 4101, 4112,
  4118, 4127, 4133, 4153, 4159, 4168, 4174, 4185,
  4191, 4200, 4206, 4070, 4076, 4085, 4091, 4102,
  4108, 4117, 4123, 4143, 4149, 4158, 4164, 4175,
  4181, 4190, 4196, 4221, 4227, 4236, 4242, 4253,
  4259, 4268, 4274, 4294, 4300, 4309, 4315, 4326,
  4332, 4341, 4347, 4370, 4376, 4385, 4391, 4402,
  4408, 4417, 4423, 4443, 4449, 4458, 4464, 4475,
  4481, 4490, 4496, 4521, 4527, 4536, 4542, 4553,
  4559, 4568, 4574, 4594, 4600, 4609, 4615, 4626,
  4632, 4641, 4647, 3515, 3521, 3530, 3536, 3547,
  3553, 3562, 3568, 3588, 3594, 3603, 3609, 3620,
  3626, 3635, 3641, 3666, 3672, 3681, 3687, 3698,
  3704, 3713, 3719, 3739, 3745, 3754, 3760, 3771,
  3777, 3786, 3792, 3815, 3821, 3830, 3836, 3847,
  3853, 3862, 3868, 3888, 3894, 3903, 3909, 3920,
  3926, 3935, 3941, 3966, 3972, 3981, 3987, 3998,
  4004, 4013, 4019, 4039, 4045, 4054, 4060, 4071,
  4077, 4086, 4092, 3956, 3962, 3971, 3977, 3988,
  3994, 4003, 4009, 4029, 4035, 4044, 4050, 4061,
  4067, 4076, 4082, 4107, 4113, 4122, 4128, 4139,
  4145, 4154, 4160, 4180, 4186, 4195, 4201, 4212,
  4218, 4227, 4233, 4256, 4262, 4271, 4277, 4288,
  4294, 4303, 4309, 4329, 4335, 4344, 4350, 4361,
  4367, 4376, 4382, 4407, 4413, 4422, 4428, 4439,
  4445, 4454, 4460, 4480, 4486, 4495, 4501, 4512,
  4518, 4527, 4533, 4328, 4334, 4343, 4349, 4360,
  4366, 4375, 4381, 4401, 4407, 4416, 4422, 4433,
  4439, 4448, 4454, 4479, 4485, 4494, 4500, 4511,
  4517, 4526, 4532, 4552, 4558, 4567, 4573, 4584,
  4590, 4599, 4605, 4628, 4634, 4643, 4649, 4660,
  4666, 4675, 4681, 4701, 4707, 4716, 4722, 4733,
  4739, 4748, 4754, 4779, 4785, 4794, 4800, 4811,
  4817, 4826, 4832, 4852, 4858, 4867, 4873, 4884,
  4890, 4899, 4905, 4769, 4775, 4784, 4790, 4801,
  4807, 4816, 4822, 4842, 4848, 4857, 4863, 4874,
  4880, 4889, 4895, 4920, 4926, 4935, 4941, 4952,
  4958, 4967, 4973, 4993, 4999, 5008, 5014, 5025,
  5031, 5040, 5046, 5069, 5075, 5084, 5090, 5101,
  5107, 5116, 5122, 5142, 5148, 5157, 5163, 5174,
  5180, 5189, 5195, 5220, 5226, 5235, 5241, 5252,
  5258, 5267, 5273, 5293, 5299, 5308, 5314, 5325,
  5331, 5340, 5346, 4604, 4610, 4619, 4625, 4636,
  4642, 4651, 4657, 4677, 4683, 4692, 4698, 4709,
  4715, 4724, 4730, 4755, 4761, 4770, 4776, 4787,
  4793, 4802, 4808, 4828, 4834, 4843, 4849, 4860,
  4866, 4875, 4881, 4904, 4910, 4919, 4925, 4936,
  4942, 4951, 4957, 4977, 4983, 4992, 4998, 5009,
  5015, 5024, 5030, 5055, 5061, 5070, 5076, 5087,
  5093, 5102, 5108, 5128, 5134, 5143, 5149, 5160,
  5166, 5175, 5181, 5045, 5051, 5060, 5066, 5077,
  5083, 5092, 5098, 5118, 5124, 5133, 5139, 5150,
  5156, 5165, 5171, 5196, 5202, 5211, 5217, 5228,
  5234, 5243, 5249, 5269, 5275, 5284, 5290, 5301,
  5307, 5316, 5322, 5345, 5351, 5360, 5366, 5377,
  5383, 5392, 5398, 5418, 5424, 5433, 5439, 5450,
  5456, 5465, 5471, 5496, 5502, 5511, 5517, 5528,
  5534, 5543, 5549, 5569, 5575, 5584, 5590, 5601,
  5607, 5616, 5622, 5417, 5423, 5432, 5438, 5449,
  5455, 5464, 5470, 5490, 5496, 5505, 5511, 5522,
  5528, 5537, 5543, 5568, 5574, 5583, 5589, 5600,
  5606, 5615, 5621, 5641, 5647, 5656, 5662, 5673,
  5679, 5688, 5694, 5717, 5723, 5732, 5738, 5749,
  5755, 5764, 5770, 5790, 5796, 5805, 5811, 5822,
  5828, 5837, 5843, 5868, 5874, 5883, 5889, 5900,
  5906, 5915, 5921, 5941, 5947, 5956, 5962, 5973,
  5979, 5988, 5994, 5858, 5864, 5873, 5879, 5890,
  5896, 5905, 5911, 5931, 5937, 5946, 5952, 5963,
  5969, 5978, 5984, 6009, 6015, 6024, 6030, 6041,
  6047, 6056, 6062, 6082, 6088, 6097, 6103, 6114,
  6120, 6129, 6135, 6158, 6164, 6173, 6179, 6190,
  6196, 6205, 6211, 6231, 6237, 6246, 6252, 6263,
  6269, 6278, 6284, 6309, 6315, 6324, 6330, 6341,
  6347, 6356, 6362, 6382, 6388, 6397, 6403, 6414,
  6420, 6429, 6435, 3515, 3521, 3530, 3536, 3547,
  3553, 3562, 3568, 3588, 3594, 3603, 3609, 3620,
  3626, 3635, 3641, 3666, 3672, 3681, 3687, 3698,
  3704, 3713, 3719, 3739, 3745, 3754, 3760, 3771,
  3777, 3786, 3792, 3815, 3821, 3830, 3836, 3847,
  3853, 3862, 3868, 3888, 3894, 3903, 3909, 3920,
  3926, 3935, 3941, 3966, 3972, 3981, 3987, 3998,
  4004, 4013, 4019, 4039, 4045, 4054, 4060, 4071,
  4077, 4086, 4092, 3956, 3962, 3971, 3977, 3988,
  3994, 4003, 4009, 4029, 4035, 4044, 4050, 4061,
  4067, 4076, 4082, 4107, 4113, 4122, 4128, 4139,
  4145, 4154, 4160, 4180, 4186, 4195, 4201, 4212,
  4218, 4227, 4233, 4256, 4262, 4271, 4277, 4288,
  4294, 4303, 4309, 4329, 4335, 4344, 4350, 4361,
  4367, 4376, 4382, 4407, 4413, 4422, 4428, 4439,
  4445, 4454, 4460, 4480, 4486, 4495, 4501, 4512,
  4518, 4527, 4533, 4328, 4334, 4343, 4349, 4360,
  4366, 4375, 4381, 4401, 4407, 4416, 4422, 4433,
  4439, 4448, 4454, 4479, 4485, 4494, 4500, 4511,
  4517, 4526, 4532, 4552, 4558, 4567, 4573, 4584,
  4590, 4599, 4605, 4628, 4634, 4643, 4649, 4660,
  4666, 4675, 4681, 4701, 4707, 4716, 4722, 4733,
  4739, 4748, 4754, 4779, 4785, 4794, 4800, 4811,
  4817, 4826, 4832, 4852, 4858, 4867, 4873, 4884,
  4890, 4899, 4905, 4769, 4775, 4784, 4790, 4801,
  4807, 4816, 4822, 4842, 4848, 4857, 4863, 4874,
  4880, 4889, 4895, 4920, 4926, 4935, 4941, 4952,
  4958, 4967, 4973, 4993, 4999, 5008, 5014, 5025,
  5031, 5040, 5046, 5069, 5075, 5084, 5090, 5101,
  5107, 5116, 5122, 5142, 5148, 5157, 5163, 5174,
  5180, 5189, 5195, 5220, 5226, 5235, 5241, 5252,
  5258, 5267, 5273, 5293, 5299, 5308, 5314, 5325,
  5331, 5340, 5346, 4604, 4610, 4619, 4625, 4636,
  4642, 4651, 4657, 4677, 4683, 4692, 4698, 4709,
  4715, 4724, 4730, 4755, 4761, 4770, 4776, 4787,
  4793, 4802, 4808, 4828, 4834, 4843, 4849, 4860,
  4866, 4875, 4881, 4904, 4910, 4919, 4925, 4936,
  4942, 4951, 4957, 4977, 4983, 4992, 4998, 5009,
  5015, 5024, 5030, 5055, 5061, 5070, 5076, 5087,
  5093, 5102, 5108, 5128, 5134, 5143, 5149, 5160,
  5166, 5175, 5181, 5045, 5051, 5060, 5066, 5077,
  5083, 5092, 5098, 5118, 5124, 5133, 5139, 5150,
  5156, 5165, 5171, 5196, 5202, 5211, 5217, 5228,
  5234, 5243, 5249, 5269, 5275, 5284, 5290, 5301,
  5307, 5316, 5322, 5345, 5351, 5360, 5366, 5377,
  5383, 5392, 5398, 5418, 5424, 5433, 5439, 5450,
  5456, 5465, 5471, 5496, 5502, 5511, 5517, 5528,
  5534, 5543, 5549, 5569, 5575, 5584, 5590, 5601,
  5607, 5616, 5622, 5417, 5423, 5432, 5438, 5449,
  5455, 5464, 5470, 5490, 5496, 5505, 5511, 5522,
  5528, 5537, 5543, 5568, 5574, 5583, 5589, 5600,
  5606, 5615, 5621, 5641, 5647, 5656, 5662, 5673,
  5679, 5688, 5694, 5717, 5723, 5732, 5738, 5749,
  5755, 5764, 5770, 5790, 5796, 5805, 5811, 5822,
  5828, 5837, 5843, 5868, 5874, 5883, 5889, 5900,
  5906, 5915, 5921, 5941, 5947, 5956, 5962, 5973,
  5979, 5988, 5994, 5858, 5864, 5873, 5879, 5890,
  5896, 5905, 5911, 5931, 5937, 5946, 5952, 5963,
  5969, 5978, 5984, 6009, 6015, 6024, 6030, 6041,
  6047, 6056, 6062, 6082, 6088, 6097, 6103, 6114,
  6120, 6129, 6135, 6158, 6164, 6173, 6179, 6190,
  6196, 6205, 6211, 6231, 6237, 6246, 6252, 6263,
  6269, 6278, 6284, 6309, 6315, 6324, 6330, 6341,
  6347, 6356, 6362, 6382, 6388, 6397, 6403, 6414,
  6420, 6429, 6435, 5303, 5309, 5318, 5324, 5335,
  5341, 5350, 5356, 5376, 5382, 5391, 5397, 5408,
  5414, 5423, 5429, 5454, 5460, 5469, 5475, 5486,
  5492, 5501, 5507, 5527, 5533, 5542, 5548, 5559,
  5565, 5574, 5580, 5603, 5609, 5618, 5624, 5635,
  5641, 5650, 5656, 5676, 5682, 5691, 5697, 5708,
  5714, 5723, 5729, 5754, 5760, 5769, 5775, 5786,
  5792, 5801, 5807, 5827, 5833, 5842, 5848, 5859,
  5865, 5874, 5880, 5744, 5750, 5759, 5765, 5776,
  5782, 5791, 5797, 5817, 5823, 5832, 5838, 5849,
  5855, 5864, 5870, 5895, 5901, 5910, 5916, 5927,
  5933, 5942, 5948, 5968, 5974, 5983, 5989, 6000,
  6006, 6015, 6021, 6044, 6050, 6059, 6065, 6076,
  6082, 6091, 6097, 6117, 6123, 6132, 6138, 6149,
  6155, 6164, 6170, 6195, 6201, 6210, 6216, 6227,
  6233, 6242, 6248, 6268, 6274, 6283, 6289, 6300,
  6306, 6315, 6321, 6116, 6122, 6131, 6137, 6148,
  6154, 6163, 6169, 6189, 6195, 6204, 6210, 6221,
  6227, 6236, 6242, 6267, 6273, 6282, 6288, 6299,
  6305, 6314, 6320, 6340, 6346, 6355, 6361, 6372,
  6378, 6387, 6393, 6416, 6422, 6431, 6437, 6448,
  6454, 6463, 6469, 6489, 6495, 6504, 6510, 6521,
  6527, 6536, 6542, 6567, 6573, 6582, 6588, 6599,
  6605, 6614, 6620, 6640, 6646, 6655, 6661, 6672,
  6678, 6687, 6693, 6557, 6563, 6572, 6578, 6589,
  6595, 6604, 6610, 6630, 6636, 6645, 6651, 6662,
  6668, 6677, 6683, 6708, 6714, 6723, 6729, 6740,
  6746, 6755, 6761, 6781, 6787, 6796, 6802, 6813,
  6819, 6828, 6834, 6857, 6863, 6872, 6878, 6889,
  6895, 6904, 6910, 6930, 6936, 6945, 6951, 6962,
  6968, 6977, 6983, 7008, 7014, 7023, 7029, 7040,
  7046, 7055, 7061, 7081, 7087, 7096, 7102, 7113,
  7119, 7128, 7134, 6392, 6398, 6407, 6413, 6424,
  6430, 6439, 6445, 6465, 6471, 6480, 6486, 6497,
  6503, 6512, 6518, 6543, 6549, 6558, 6564, 6575,
  6581, 6590, 6596, 6616, 6622, 6631, 6637, 6648,
  6654, 6663, 6669, 6692, 6698, 6707, 6713, 6724,
  6730, 6739, 6745, 6765, 6771, 6780, 6786, 6797,
  6803, 6812, 6818, 6843, 6849, 6858, 6864, 6875,
  6881, 6890, 6896, 6916, 6922, 6931, 6937, 6948,
  6954, 6963, 6969, 6833, 6839, 6848, 6854, 6865,
  6871, 6880, 6886, 6906, 6912, 6921, 6927, 6938,
  6944, 6953, 6959, 6984, 6990, 6999, 7005, 7016,
  7022, 7031, 7037, 7057, 7063, 7072, 7078, 7089,
  7095, 7104, 7110, 7133, 7139, 7148, 7154, 7165,
  7171, 7180, 7186, 7206, 7212, 7221, 7227, 7238,
  7244, 7253, 7259, 7284, 7290, 7299, 7305, 7316,
  7322, 7331, 7337, 7357, 7363, 7372, 7378, 7389,
  7395, 7404, 7410, 7205, 7211, 7220, 7226, 7237,
  7243, 7252, 7258, 7278, 7284, 7293, 7299, 7310,
  7316, 7325, 7331, 7356, 7362, 7371, 7377, 7388,
  7394, 7403, 7409, 7429, 7435, 7444, 7450, 7461,
  7467, 7476, 7482, 7505, 7511, 7520, 7526, 7537,
  7543, 7552, 7558, 7578, 7584, 7593, 7599, 7610,
  7616, 7625, 7631, 7656, 7662, 7671, 7677, 7688,
  7694, 7703, 7709, 7729, 7735, 7744, 7750, 7761
};

//------------------------------------------------------------------------------
// Tables for level coding

const uint8_t RDVP8EncBands[16 + 1] = {
  0, 1, 2, 3, 6, 4, 5, 6, 6, 6, 6, 6, 6, 6, 6, 7,
  0  // sentinel
};

//------------------------------------------------------------------------------
// Mode costs

static int GetResidualCost(int ctx0, const VP8Residual* const res) {
  int n = res->first;
  // should be prob[RDVP8EncBands[n]], but it's equivalent for n=0 or 1
  const int p0 = res->prob[n][ctx0][0];
  CostArrayPtr const costs = res->costs;
  const uint16_t* t = costs[n][ctx0];
  // bit_cost(1, p0) is already incorporated in t[] tables, but only if ctx != 0
  // (as required by the syntax). For ctx0 == 0, we need to add it here or it'll
  // be missing during the loop.
  int cost = (ctx0 == 0) ? VP8BitCost(1, p0) : 0;

  if (res->last < 0) {
    return VP8BitCost(0, p0);
  }
  for (; n < res->last; ++n) {
    const int v = abs(res->coeffs[n]);
    const int ctx = (v >= 2) ? 2 : v;
    cost += VP8LevelCost(t, v);
    t = costs[n + 1][ctx];
  }
  // Last coefficient is always non-zero
  {
    const int v = abs(res->coeffs[n]);
    assert(v != 0);
    cost += VP8LevelCost(t, v);
    if (n < 15) {
      const int b = RDVP8EncBands[n + 1];
      const int ctx = (v == 1) ? 1 : 2;
      const int last_p0 = res->prob[b][ctx][0];
      cost += VP8BitCost(0, last_p0);
    }
  }
  return cost;
}

static void SetResidualCoeffs(const int16_t* const coeffs,
                              VP8Residual* const res) {
  int n;
  res->last = -1;
  assert(res->first == 0 || coeffs[0] == 0);
  for (n = 15; n >= 0; --n) {
    if (coeffs[n]) {
      res->last = n;
      break;
    }
  }
  res->coeffs = coeffs;
}

//------------------------------------------------------------------------------
// init function

VP8GetResidualCostFunc VP8GetResidualCost;
VP8SetResidualCoeffsFunc VP8SetResidualCoeffs;

extern void RDVP8EncDspCostInitMIPS32(void);
extern void RDVP8EncDspCostInitMIPSdspR2(void);
extern void RDVP8EncDspCostInitSSE2(void);

static volatile VP8CPUInfo cost_last_cpuinfo_used =
    (VP8CPUInfo)&cost_last_cpuinfo_used;

WEBP_TSAN_IGNORE_FUNCTION void RDVP8EncDspCostInit(void) {
  if (cost_last_cpuinfo_used == VP8GetCPUInfo) return;

  VP8GetResidualCost = GetResidualCost;
  VP8SetResidualCoeffs = SetResidualCoeffs;

  // If defined, use CPUInfo() to overwrite some pointers with faster versions.
  if (VP8GetCPUInfo != NULL) {
#if defined(WEBP_USE_MIPS32)
    if (VP8GetCPUInfo(kMIPS32)) {
      RDVP8EncDspCostInitMIPS32();
    }
#endif
#if defined(WEBP_USE_MIPS_DSP_R2)
    if (VP8GetCPUInfo(kMIPSdspR2)) {
      RDVP8EncDspCostInitMIPSdspR2();
    }
#endif
#if defined(WEBP_USE_SSE2)
    if (VP8GetCPUInfo(kSSE2)) {
      RDVP8EncDspCostInitSSE2();
    }
#endif
  }

  cost_last_cpuinfo_used = VP8GetCPUInfo;
}

//------------------------------------------------------------------------------