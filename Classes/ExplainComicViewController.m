//
//  ExplainComicViewController.m
//  xkcd
//
//  Created by Stuart McHattie on 22/06/2013.
//
//

#import "ExplainComicViewController.h"
#import "Comic.h"

@interface ExplainComicViewController ()

@property (nonatomic) Comic *comic;

@end

@implementation ExplainComicViewController

- (id)initWithComic:(Comic *)comic
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _comic = comic;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
