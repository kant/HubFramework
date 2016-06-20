#import "HUBComponentRegistryImplementation.h"

#import "HUBComponent.h"
#import "HUBComponentIdentifier.h"
#import "HUBComponentFactory.h"
#import "HUBComponentFactoryShowcaseNameProvider.h"
#import "HUBComponentModel.h"
#import "HUBComponentFallbackHandler.h"

NS_ASSUME_NONNULL_BEGIN

@interface HUBComponentRegistryImplementation ()

@property (nonatomic, strong, readonly) id<HUBComponentFallbackHandler> fallbackHandler;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, id<HUBComponentFactory>> *componentFactories;

@end

@implementation HUBComponentRegistryImplementation

- (instancetype)initWithFallbackHandler:(id<HUBComponentFallbackHandler>)fallbackHandler
{
    self = [super init];
    
    if (self) {
        _fallbackHandler = fallbackHandler;
        _componentFactories = [NSMutableDictionary new];
    }
    
    return self;
}

#pragma mark - API

- (NSArray<HUBComponentIdentifier *> *)showcaseableComponentIdentifiers
{
    NSMutableArray<HUBComponentIdentifier *> * const componentIdentifiers = [NSMutableArray new];
    
    for (NSString * const namespace in self.componentFactories) {
        id<HUBComponentFactory> const factory = self.componentFactories[namespace];
        
        if (![factory conformsToProtocol:@protocol(HUBComponentFactoryShowcaseNameProvider)]) {
            continue;
        }
        
        NSArray<NSString *> * const names = ((id<HUBComponentFactoryShowcaseNameProvider>)factory).showcaseableComponentNames;
        
        for (NSString * const name in names) {
            HUBComponentIdentifier * const identifier = [[HUBComponentIdentifier alloc] initWithNamespace:namespace name:name];
            [componentIdentifiers addObject:identifier];
        }
    }
    
    return [componentIdentifiers copy];
}

- (id<HUBComponent>)createComponentForModel:(id<HUBComponentModel>)model
{
    id<HUBComponentFactory> const factory = self.componentFactories[model.componentIdentifier.componentNamespace];
    id<HUBComponent> const component = [factory createComponentForName:model.componentIdentifier.componentName];
    
    if (component != nil) {
        return component;
    }
    
    return [self.fallbackHandler createFallbackComponentForCategory:model.componentCategory];
}

#pragma mark - HUBComponentRegistry

- (void)registerComponentFactory:(id<HUBComponentFactory>)componentFactory forNamespace:(NSString *)componentNamespace
{
    NSAssert(self.componentFactories[componentNamespace] == nil,
             @"Attempted to register a component factory for a namespace that is already registered: %@",
             componentNamespace);

    self.componentFactories[componentNamespace] = componentFactory;
}

- (void)unregisterComponentFactoryForNamespace:(NSString *)componentNamespace
{
    self.componentFactories[componentNamespace] = nil;
}

@end

NS_ASSUME_NONNULL_END