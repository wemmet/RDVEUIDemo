//
//  RDTPCircularBuffer.c
//  Circular/Ring buffer implementation
//
//  Created by Michael Tyson on 10/12/2011.
//  Copyright 2011-2012 A Tasty Pixel. All rights reserved.


#include "RDTPCircularBuffer.h"
#include <mach/mach.h>
#include <stdio.h>

#define reportResult(result,operation) (_reportResult((result),(operation),strrchr(__FILE__, '/')+1,__LINE__))
static inline bool _reportResult(kern_return_t result, const char *operation, const char* file, int line) {
    if ( result != ERR_SUCCESS ) {
        printf("%s:%d: %s: %s\n", file, line, operation, mach_error_string(result)); 
        return false;
    }
    return true;
}




bool RDTPCircularBufferInit(RDTPCircularBuffer *buffer, int length) {
    g_rdtpCBCount++;
    
    if(g_fristinit){
        buffer->length = 0;
    }
    
    g_fristinit = 1;
    printf("g_rdtpCBCount:%d \n",g_rdtpCBCount);

    
    if (g_isRDBufferInited) {
    
        printf("RDTPCircularBufferInit has been init! talker!!!!");
        if(buffer->length>0){
            return true;
            
        }
    }
    
    printf("\n\n***RDTPCircularBufferInit***\n\n");
    // Keep trying until we get our buffer, needed to handle race conditions
    int retries = 3;
    while ( true ) {

        buffer->length = (int32_t)round_page(length);    // We need whole page sizes

        // Temporarily allocate twice the length, so we have the contiguous address space to
        // support a second instance of the buffer directly after
        vm_address_t bufferAddress;
        kern_return_t result = vm_allocate(mach_task_self(),
                                           &bufferAddress,
                                           buffer->length * 2,
                                           VM_FLAGS_ANYWHERE); // allocate anywhere it'll fit
        if ( result != ERR_SUCCESS ) {
            if ( retries-- == 0 ) {
                reportResult(result, "Buffer allocation");
                return false;
            }
            // Try again if we fail
            continue;
        }
        
        // Now replace the second half of the allocation with a virtual copy of the first half. Deallocate the second half...
        result = vm_deallocate(mach_task_self(),
                               bufferAddress + buffer->length,
                               buffer->length);
        if ( result != ERR_SUCCESS ) {
            if ( retries-- == 0 ) {
                reportResult(result, "Buffer deallocation");
                return false;
            }
            // If this fails somehow, deallocate the whole region and try again
            vm_deallocate(mach_task_self(), bufferAddress, buffer->length);
            continue;
        }
        
        // Re-map the buffer to the address space immediately after the buffer
        vm_address_t virtualAddress = bufferAddress + buffer->length;
        vm_prot_t cur_prot, max_prot;
        result = vm_remap(mach_task_self(),
                          &virtualAddress,   // mirror target
                          buffer->length,    // size of mirror
                          0,                 // auto alignment
                          0,                 // force remapping to virtualAddress
                          mach_task_self(),  // same task
                          bufferAddress,     // mirror source
                          0,                 // MAP READ-WRITE, NOT COPY
                          &cur_prot,         // unused protection struct
                          &max_prot,         // unused protection struct
                          VM_INHERIT_DEFAULT);
        if ( result != ERR_SUCCESS ) {
            if ( retries-- == 0 ) {
                reportResult(result, "Remap buffer memory");
                return false;
            }
            // If this remap failed, we hit a race condition, so deallocate and try again
            vm_deallocate(mach_task_self(), bufferAddress, buffer->length);
            continue;
        }
        
        if ( virtualAddress != bufferAddress+buffer->length ) {
            // If the memory is not contiguous, clean up both allocated buffers and try again
            if ( retries-- == 0 ) {
                printf("Couldn't map buffer memory to end of buffer\n");
                return false;
            }

            vm_deallocate(mach_task_self(), virtualAddress, buffer->length);
            vm_deallocate(mach_task_self(), bufferAddress, buffer->length);
            continue;
        }
        
        buffer->buffer = (void*)bufferAddress;
        buffer->fillCount = 0;
        buffer->head = buffer->tail = 0;
        g_isRDBufferInited=1;
        return true;
    }
    return false;
}

void RDTPCircularBufferCleanup(RDTPCircularBuffer *buffer) {
    
   
    
    if (g_isRDBufferInited==0) {
        return;
    }
    g_rdtpCBCount--;
    if (g_rdtpCBCount>0) {
        return;
    }
    printf("g_rdtpCBCount:%d\n ",g_rdtpCBCount);
    vm_deallocate(mach_task_self(), (vm_address_t)buffer->buffer, buffer->length * 2);
    memset(buffer, 0, sizeof(RDTPCircularBuffer));
    g_isRDBufferInited=0;
    printf("\n\n***RDTPCircularBufferCleanup***\n\n");
}

void RDTPCircularBufferClear(RDTPCircularBuffer *buffer) {
    int32_t fillCount;
    if ( RDTPCircularBufferTail(buffer, &fillCount) ) {
        RDTPCircularBufferConsume(buffer, fillCount);
    }
}
