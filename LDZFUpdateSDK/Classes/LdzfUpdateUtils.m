//
//  LdzfUpdateUtils.m
//  IU_UpdateSDK
//
//

#import "LdzfUpdateUtils.h"

@implementation LdzfUpdateUtils

+ (NSString *)encryptRSAWithString:(NSString *)string publicKey:(NSString *)publicKey
{
    string = [string stringByRemovingPercentEncoding];
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];

    if (!data || !publicKey)
    {
        return nil;
    }

    SecKeyRef keyRef = [self addPublicKey:publicKey];

    if (!keyRef)
    {
        return nil;
    }

    size_t outlen = SecKeyGetBlockSize(keyRef) * sizeof(uint8_t);

    NSString *ret = nil;

    // 分配内存块, 用于存放要加密的数据段
    uint8_t *cipherBuffer = malloc(outlen * sizeof(uint8_t));

    /*
     为什么这里要减12而不是减11?
     苹果官方文档给出的说明是，加密时，如果sec padding使用的是kSecPaddingPKCS1，
     那么支持的最长加密长度为SecKeyGetBlockSize()-11，
     这里说的最长加密长度，我估计是包含了字符串最后的空字符'\0'，
     因为在实际应用中我们是不考虑'\0'的，所以，支持的真正最长加密长度应为SecKeyGetBlockSize()-12
     */
    size_t blockSize = outlen - 12;

    // 分段的count
    size_t blockCount = (size_t)ceil([data length] / (double)blockSize);

    //后面分段处理的data
    NSMutableData *encryptedData = [NSMutableData data];

    // 分段加密
    for (NSUInteger i = 0; i < blockCount; i++)
    {
        NSUInteger loc = i * blockSize;

        // 数据段的实际大小。最后一段可能比blockSize小。
        NSUInteger bufferSize = MIN(blockSize,[data length] - loc);

        // 截取需要加密的数据段
        NSData *buffer = [data subdataWithRange:NSMakeRange(loc, bufferSize)];

        // status 加密的结果  seckeyEncrypt 加密
        OSStatus status = SecKeyEncrypt(keyRef, kSecPaddingPKCS1, (const uint8_t *)[buffer bytes], [buffer length], cipherBuffer, &outlen);

        if (status == noErr)
        {
            //加密后的data
            NSData *encryptedBytes = [[NSData alloc] initWithBytes:(const void *)cipherBuffer length:outlen];
            // 追加加密后的数据段
            [encryptedData appendData:encryptedBytes];
        }
        else
        {
            if (cipherBuffer)
            {
                free(cipherBuffer);
            }
            return nil;
        }
    }

    NSData *resultData = [encryptedData base64EncodedDataWithOptions:0];
    ret = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
    free(cipherBuffer);
    CFRelease(keyRef);

    return ret;
}

+ (SecKeyRef)addPublicKey:(NSString *)key
{
    NSRange spos = [key rangeOfString:@"-----BEGIN PUBLIC KEY-----"];
    NSRange epos = [key rangeOfString:@"-----END PUBLIC KEY-----"];

    if (spos.location != NSNotFound && epos.location != NSNotFound) {
        NSUInteger s = spos.location + spos.length;
        NSUInteger e = epos.location;
        NSRange range = NSMakeRange(s, e-s);
        key = [key substringWithRange:range];
    }

    key = [key stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@" "  withString:@""];

    // This will be base64 encoded, decode it.
    NSData *data = [[NSData alloc] initWithBase64EncodedString:key options:NSDataBase64DecodingIgnoreUnknownCharacters];
    data = [self stripPublicKeyHeader:data];
    if (!data) {
        return nil;
    }

    NSString *tag = @"what_the_fuck_is_this";
    NSData *d_tag = [NSData dataWithBytes:[tag UTF8String] length:[tag length]];

    // Delete any old lingering key with the same tag
    NSMutableDictionary *publicKey = [[NSMutableDictionary alloc] init];
    [publicKey setObject:(__bridge id) kSecClassKey forKey:(__bridge id)kSecClass];
    [publicKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [publicKey setObject:d_tag forKey:(__bridge id)kSecAttrApplicationTag];
    SecItemDelete((__bridge CFDictionaryRef)publicKey);

    // Add persistent version of the key to system keychain
    [publicKey setObject:data forKey:(__bridge id)kSecValueData];
    [publicKey setObject:(__bridge id) kSecAttrKeyClassPublic forKey:(__bridge id)
     kSecAttrKeyClass];
    [publicKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)
     kSecReturnPersistentRef];

    CFTypeRef persistKey = nil;
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)publicKey, &persistKey);
    if (persistKey != nil){
        CFRelease(persistKey);
    }
    if ((status != noErr) && (status != errSecDuplicateItem)) {
        return nil;
    }

    [publicKey removeObjectForKey:(__bridge id)kSecValueData];
    [publicKey removeObjectForKey:(__bridge id)kSecReturnPersistentRef];
    [publicKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef];
    [publicKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];

    // Now fetch the SecKeyRef version of the key
    SecKeyRef keyRef = nil;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)publicKey, (CFTypeRef *)&keyRef);
    if(status != noErr){
        return nil;
    }

    return keyRef;
}

+ (NSData *)stripPublicKeyHeader:(NSData *)d_key
{
    // Skip ASN.1 public key header
    if (d_key == nil) return nil;

    unsigned long len = [d_key length];
    if (!len) return nil;

    unsigned char *c_key = (unsigned char *)[d_key bytes];
    unsigned int  idx    = 0;

    if (c_key[idx++] != 0x30) return nil;

    if (c_key[idx] > 0x80) idx += c_key[idx] - 0x80 + 1;
    else idx++;

    // PKCS #1 rsaEncryption szOID_RSA_RSA
    static unsigned char seqiod[] =
    { 0x30,   0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01,
        0x01, 0x05, 0x00 };
    if (memcmp(&c_key[idx], seqiod, 15)) return(nil);

    idx += 15;

    if (c_key[idx++] != 0x03) return(nil);

    if (c_key[idx] > 0x80) idx += c_key[idx] - 0x80 + 1;
    else idx++;

    if (c_key[idx++] != '\0') return(nil);

    // Now make a new NSData from this buffer
    return([NSData dataWithBytes:&c_key[idx] length:len - idx]);
}

+ (NSString *)stringWithObject:(id)obj
{
    NSString *string = nil;

    if ([NSJSONSerialization isValidJSONObject:obj])
    {
        NSData *data = [NSJSONSerialization dataWithJSONObject:obj options:0 error:nil];

        if (data)
        {
            string = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        }
    }

    return string;
}

+ (NSDictionary *)objectFromJsonString:(NSString *)jsonString
{
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;

    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData
                                                    options:NSJSONReadingAllowFragments
                                                      error:&error];

    if (jsonObject != nil && error == nil)
    {
        return jsonObject;
    }
    else
    {
        return nil;
    }
}

+ (UIColor *)colorWithHexString:(NSString *)hexString
{
    NSString *colorString = [[hexString stringByReplacingOccurrencesOfString:@"#" withString:@""] uppercaseString];
    CGFloat alpha, red, blue, green;
    switch ([colorString length]) {
    case 3: // #RGB
        alpha = 1.0f;
        red = [self colorComponentFrom:colorString start:0 length:1];
        green = [self colorComponentFrom:colorString start:1 length:1];
        blue = [self colorComponentFrom:colorString start:2 length:1];
        break;
    case 4: // #ARGB
        alpha = [self colorComponentFrom:colorString start:0 length:1];
        red = [self colorComponentFrom:colorString start:1 length:1];
        green = [self colorComponentFrom:colorString start:2 length:1];
        blue = [self colorComponentFrom:colorString start:3 length:1];
        break;
    case 6: // #RRGGBB
        alpha = 1.0f;
        red = [self colorComponentFrom:colorString start:0 length:2];
        green = [self colorComponentFrom:colorString start:2 length:2];
        blue = [self colorComponentFrom:colorString start:4 length:2];
        break;
    case 8: // #AARRGGBB
        alpha = [self colorComponentFrom:colorString start:0 length:2];
        red = [self colorComponentFrom:colorString start:2 length:2];
        green = [self colorComponentFrom:colorString start:4 length:2];
        blue = [self colorComponentFrom:colorString start:6 length:2];
        break;
    default:
        return nil;
    }

    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

+ (CGFloat)colorComponentFrom:(NSString *)string start:(NSUInteger)start length:(NSUInteger)length
{
    NSString *substring = [string substringWithRange:NSMakeRange(start, length)];
    NSString *fullHex = length == 2 ? substring : [NSString stringWithFormat:@"%@%@", substring, substring];
    unsigned hexComponent;
    [[NSScanner scannerWithString:fullHex] scanHexInt:&hexComponent];
    return hexComponent / 255.0;
}
@end
