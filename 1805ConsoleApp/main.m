//
//  main.m
//  1805ConsoleApp
//
//  Created by iOS-School-1 on 18.05.17.
//  Copyright © 2017 Learning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "pthread.h"

#define SUCCESS 0

static NSArray<NSNumber *> *collection;
static const NSInteger maxThreadCount = 3;

pthread_mutex_t condVarMutex;
pthread_cond_t condVar;

//Task struct
typedef struct Task{
    CFTypeRef collection;
    NSInteger threadID;
    bool finished;
    NSInteger sum;
} Task;

void * threadEnumerateArray(void *);
bool checkCondition (Task **);

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        collection = @[@(1),@(2),@(3),@(4),@(5),@(6),@(7),@(8),@(9),@(10),@(11),@(12),@(13),@(14),@(15)];
        Task *allThreadArgs[maxThreadCount];
        pthread_mutex_init(&condVarMutex, NULL);
        pthread_cond_init(&condVar, NULL);
        
        NSInteger addition = collection.count%maxThreadCount;
        
        //Fork
        for (NSInteger i= 0; i<maxThreadCount; ++i) {
            NSInteger length = collection.count/maxThreadCount;
            NSInteger step = collection.count/maxThreadCount;
            
            if(addition !=0 & i ==(maxThreadCount-1)){
                length = length+addition;
            }
            
            NSRange subarrayRange = NSMakeRange(i*step, length);
            pthread_t thread;
            Task *args = malloc(sizeof(Task));
            args->threadID = i;
            args->collection = (void *)CFBridgingRetain([collection subarrayWithRange:subarrayRange]);
            args->finished = false;
            allThreadArgs[i] = args;
            pthread_create(&thread, NULL, threadEnumerateArray, args);
        }
        pthread_mutex_lock(&condVarMutex);
        
        while (!checkCondition(allThreadArgs)) {
            //Condvar waiting
            
            pthread_cond_wait(&condVar, &condVarMutex);
        }
        //Join
        
        NSInteger result = 0;
        for (NSInteger i =0; i<maxThreadCount; ++i) {
            Task *args = allThreadArgs[i];
            result = result +args->sum;
        }
        NSLog(@"Forl-join result %lu" , result);
        
        for (NSInteger i =0; i<maxThreadCount; ++i) {
            Task * args = allThreadArgs[i];
            free(args);
            args = NULL;
        }
        pthread_mutex_unlock(&condVarMutex);
        
        pthread_mutex_destroy(&condVarMutex);
        pthread_cond_destroy(&condVar);
        
        __block NSInteger gcdResult = 0;
        __block NSInteger iterations = 0;
        
        dispatch_apply([collection count], dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t index){
            gcdResult = gcdResult + collection[index].integerValue;
            ++iterations;
        });
        NSLog(@"GCD result %lu", gcdResult);
        NSLog(@"Right count %lu", [collection count]);
        NSLog(@"Iterations %lu", iterations);
    }
    return 0;
}

bool checkCondition(Task ** threadArguments){
    bool result = true;
    for (NSInteger i =0; i<maxThreadCount; ++i) {
        result = result & threadArguments[i] -> finished;
    }
    return result;
}

void * threadEnumerateArray(void *args){
    Task *arguments = (Task *) args;
    NSArray<NSNumber *> *array = (NSArray<NSNumber *> *) CFBridgingRelease(arguments->collection);
    NSInteger sum = 0;
    
    for (NSNumber *number in array) {
        sum = sum + number.integerValue;
        NSLog(@"Thread: %lu number: %@", arguments->threadID, number);
    }

    pthread_mutex_lock(&condVarMutex);
    arguments-> finished = true;
    arguments->sum = sum;
    pthread_cond_signal(&condVar);
    
    pthread_mutex_unlock(&condVarMutex);
    return SUCCESS;
}










