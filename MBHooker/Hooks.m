
//

#import "Hooks.h"
#import "fishhook.h"
#import <dlfcn.h>

@implementation Hooks

static OSStatus (*orig_SecItemAdd)(CFDictionaryRef, CFTypeRef);
static OSStatus (*orig_SecItemCopyMatching)(CFDictionaryRef, CFTypeRef);
static OSStatus (*orig_SecItemUpdate)(CFDictionaryRef, CFDictionaryRef);
static OSStatus (*orig_SecItemDelete)(CFDictionaryRef);

void enable_file_logging() {
    NSArray *allPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [allPaths firstObject];
    NSString *pathForLog = [documentsDirectory stringByAppendingPathComponent:@"secrets.txt"];
    
    freopen([pathForLog cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
}


void save_original_symbols() {
    orig_SecItemAdd = dlsym(RTLD_DEFAULT, "SecItemAdd");
    orig_SecItemCopyMatching = dlsym(RTLD_DEFAULT, "SecItemCopyMatching");
    orig_SecItemUpdate = dlsym(RTLD_DEFAULT, "SecItemUpdate");
    orig_SecItemDelete = dlsym(RTLD_DEFAULT, "SecItemDelete");
}


OSStatus my_SecItemCopyMatching(CFDictionaryRef query, CFTypeRef *result) {
    
    NSLog(@"SecItemCopyMatching hooked! \n Attributes:\n %@", query);
    return orig_SecItemCopyMatching(query, result);
}


OSStatus my_SecItemUpdate(CFDictionaryRef query, CFDictionaryRef attributesToUpdate) {
    
    NSLog(@"SecItemUpdate hooked! \n Attributes:\n %@", attributesToUpdate);
    
    return orig_SecItemUpdate(query, attributesToUpdate);
}

OSStatus my_SecItemDelete(CFDictionaryRef query) {
    
    NSLog(@"SecItemDelete hooked! \n Attributes:\n %@", query);
    
    return orig_SecItemDelete(query);
}

OSStatus my_SecItemAdd(CFDictionaryRef attributes, CFTypeRef *result) {
    
    NSLog(@"SecItemAdd hooked! \n Attributes:\n %@", attributes);
    
    return orig_SecItemAdd(attributes, result);
}

__attribute__((constructor))
static void __exterminate() {
    save_original_symbols();
    rebind_symbols((struct rebinding[4]){
        {"SecItemAdd", my_SecItemAdd},
        {"SecItemCopyMatching", my_SecItemCopyMatching},
        {"SecItemUpdate", my_SecItemUpdate},
        {"SecItemDelete", my_SecItemDelete}}, 4);
    enable_file_logging();
}


- (void)bingo {
    NSLog(@"Bingo called");
 }

@end
