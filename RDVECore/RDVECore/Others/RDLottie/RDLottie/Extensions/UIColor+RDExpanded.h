#import "RDLOTPlatformCompat.h"

// From http://github.com/ars/uicolor-utilities
#define CLAMP(val,min,max)    MIN(MAX(val,min),max)

@interface UIColor (UIColor_Expanded)
@property (nonatomic, readonly) CGColorSpaceModel colorSpaceModel;
@property (nonatomic, readonly) BOOL canProvideRGBComponents;
@property (nonatomic, readonly) CGFloat red; // Only valid if canProvideRGBComponents is YES
@property (nonatomic, readonly) CGFloat green; // Only valid if canProvideRGBComponents is YES
@property (nonatomic, readonly) CGFloat blue; // Only valid if canProvideRGBComponents is YES
@property (nonatomic, readonly) CGFloat white; // Only valid if colorSpaceModel == kCGColorSpaceModelMonochrome
@property (nonatomic, readonly) CGFloat alpha;
@property (nonatomic, readonly) UInt32 rgbHex;

- (NSString *)RDLOT_colorSpaceString;

- (NSArray *)RDLOT_arrayFromRGBAComponents;

- (BOOL)RDLOT_red:(CGFloat *)r green:(CGFloat *)g blue:(CGFloat *)b alpha:(CGFloat *)a;

- (UIColor *)RDLOT_colorByLuminanceMapping;

- (UIColor *)RDLOT_colorByMultiplyingByRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;
- (UIColor *)       RDLOT_colorByAddingRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;
- (UIColor *) RDLOT_colorByLighteningToRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;
- (UIColor *)  RDLOT_colorByDarkeningToRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;

- (UIColor *)RDLOT_colorByMultiplyingBy:(CGFloat)f;
- (UIColor *)       RDLOT_colorByAdding:(CGFloat)f;
- (UIColor *) RDLOT_colorByLighteningTo:(CGFloat)f;
- (UIColor *)  RDLOT_colorByDarkeningTo:(CGFloat)f;

- (UIColor *)RDLOT_colorByMultiplyingByColor:(UIColor *)color;
- (UIColor *)       RDLOT_colorByAddingColor:(UIColor *)color;
- (UIColor *) RDLOT_colorByLighteningToColor:(UIColor *)color;
- (UIColor *)  RDLOT_colorByDarkeningToColor:(UIColor *)color;

- (NSString *)RDLOT_stringFromColor;
- (NSString *)RDLOT_hexStringValue;

+ (UIColor *)RDLOT_randomColor;
+ (UIColor *)RDLOT_colorWithString:(NSString *)stringToConvert;
+ (UIColor *)RDLOT_colorWithRGBHex:(UInt32)hex;
+ (UIColor *)RDLOT_colorWithHexString:(NSString *)stringToConvert;

+ (UIColor *)RDLOT_colorWithName:(NSString *)cssColorName;

+ (UIColor *)RDLOT_colorByLerpingFromColor:(UIColor *)fromColor toColor:(UIColor *)toColor amount:(CGFloat)amount;

@end
