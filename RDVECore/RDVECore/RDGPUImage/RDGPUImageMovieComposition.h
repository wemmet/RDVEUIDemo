//
//  RDGPUImageMovieComposition.h
//  Givit
//
//  Created by Sean Meiners on 2013/01/25.
//
//

#import "RDGPUImageMovie.h"

@interface RDGPUImageMovieComposition : RDGPUImageMovie

@property (readwrite, retain) AVComposition *compositon;
@property (readwrite, retain) AVVideoComposition *videoComposition;
@property (readwrite, retain) AVAudioMix *audioMix;

- (id)initWithComposition:(AVComposition*)compositon
      andVideoComposition:(AVVideoComposition*)videoComposition
              andAudioMix:(AVAudioMix*)audioMix;

@end
