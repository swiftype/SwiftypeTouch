# SwiftypeTouch for Swiftype Site Search

SwiftypeTouch is a library that makes it easy to add [Swiftype-powered Site Search](http://swiftype.com/) to your iOS application.

> **Note:** This client has been developed for the [Swiftype Site Search](https://www.swiftype.com/site-search) API endpoints only. You may refer to the [Swiftype Site Search API Documentation](https://swiftype.com/documentation/site-search/overview) for additional context.

## Installing SwiftypeTouch

1. Get the code (`git clone git@github.com:swiftype/SwiftypeTouch.git`) and copy the top-level `SwiftypeTouch` directory to the directory that contains `YourProject.xcodeproj` (or use a git submodule).
2. Add `SwiftypeTouch/SwiftypeTouch.xcodeproj` to your Xcode project.
   * This can be done by dragging and dropping `SwiftypeTouch.xcodeproj` into the project browser from Finder.
3. In `YourProject.xcodeproj` Build Settings add to your `HEADER_SEARCH_PATHS` the following: `$(SRCROOT)/SwiftypeTouch/`.
4. Add `-ObjC` and `-all_load` to your project's `OTHER_LDFLAGS`.
5. Now make sure to link `libSwiftypeTouch.a` with your target.  Under your Target settings go to Build Phases. Expand "Link Binary With Libraries" hit the "+" button and select `libSwiftypeTouch.a` from the dialog.
6. Add SwiftypeTouch to the "Target Dependencies" list.

You are now ready to use SwiftypeTouch in your project.

## Quick start for crawler-based engines

If your Swiftype search engine was created with the Swiftype crawler, you can follow these steps to quickly add search that displays results in a table view. 
Results will load in a webview when selected.

1. First, makes sure you've followed the steps above.
2. Add `#import <SwiftypeTouch/STPageDocumentTypeResultsObject.h>` to the view controller implementation that will place the search bar on the screen.
3. Create a private property for `STPageDocumentTypeResultsObject` called `resultObject` in your view controller:

        @property (nonatomic, strong) STPageDocumentTypeResultsObject *resultObject;

4. In the view controller's `viewDidLoad` add the following code to get the search bar to appear:

        self.resultObject = [[STPageDocumentTypeResultsObject alloc] initWithViewController:self clientEngineKey:@"yourEngineKey"];
        [self.view addSubview:self.resultObject.searchBar];
     
To see an example of this, view the source of the [SwiftypeTouchExample application](https://github.com/swiftype/SwiftypeTouchExample).

## License

This code is made available under the MIT License. Seee LICENSE.txt for details.
