<p align="center"><img src="https://github.com/swiftype/SwiftypeTouch/blob/master/logo-app-search.png?raw=true" alt="Elastic Site Search Logo"></p>

> A first-party iOS library to add [Elastic Site Search](https://swiftype.com/documentation/site-search/overview) to iOS applications.

## Contents

+ [Getting started](#getting-started-)
+ [FAQ](#faq-)
+ [Contribute](#contribute-)
+ [License](#license-)

***

## Getting started 🐣

1. Get the code (`git clone git@github.com:swiftype/SwiftypeTouch.git`) and copy the top-level `SwiftypeTouch` directory to the directory that contains `YourProject.xcodeproj` (or use a git submodule).
2. Add `SwiftypeTouch/SwiftypeTouch.xcodeproj` to your Xcode project.
   * This can be done by dragging and dropping `SwiftypeTouch.xcodeproj` into the project browser from Finder.
3. In `YourProject.xcodeproj` Build Settings add to your `HEADER_SEARCH_PATHS` the following: `$(SRCROOT)/SwiftypeTouch/`.
4. Add `-ObjC` and `-all_load` to your project's `OTHER_LDFLAGS`.
5. Now make sure to link `libSwiftypeTouch.a` with your target.  Under your Target settings go to Build Phases. Expand "Link Binary With Libraries" hit the "+" button and select `libSwiftypeTouch.a` from the dialog.
6. Add SwiftypeTouch to the "Target Dependencies" list.

You are now ready to use SwiftypeTouch in your project.

> **Note:** This client has been developed for the [Swiftype Site Search](https://www.swiftype.com/site-search) API endpoints only. You may refer to the [Swiftype Site Search API Documentation](https://swiftype.com/documentation/site-search/overview) for additional context.

## Usage

If your Swiftype search engine was created with the Swiftype crawler, you can follow these steps to quickly add search that displays results in a table view.
Results will load in a webview when selected.

1. First, makes sure you've followed the steps above.
2. Add `#import <SwiftypeTouch/STPageDocumentTypeResultsObject.h>` to the view controller implementation that will place the search bar on the screen.
3. Create a private property for `STPageDocumentTypeResultsObject` called `resultObject` in your view controller:
```c
        @property (nonatomic, strong) STPageDocumentTypeResultsObject *resultObject;
```
4. In the view controller's `viewDidLoad` add the following code to get the search bar to appear:

```c
        self.resultObject = [[STPageDocumentTypeResultsObject alloc] initWithViewController:self clientEngineKey:@"yourEngineKey"];
        [self.view addSubview:self.resultObject.searchBar];
```
To see an example of this, view the source of the [SwiftypeTouchExample application](https://github.com/swiftype/SwiftypeTouchExample).

## FAQ 🔮

### Where do I report issues with the client?

If something is not working as expected, please open an [issue](https://github.com/swiftype/SwiftypeTouch/issues/new).

### Where can I learn more about Site Search?

Your best bet is to read the [documentation](https://swiftype.com/documentation/site-search).

### Where else can I go to get help?

You can checkout the [Elastic Site Search community discuss forums](https://discuss.elastic.co/c/site-search).

## Contribute 🚀

We welcome contributors to the project. Before you begin, a couple notes...

+ Before opening a pull request, please create an issue to [discuss the scope of your proposal](https://github.com/swiftype/SwiftypeTouch/issues).
+ Please write simple code and concise documentation, when appropriate.

## License 📗

[MIT](https://github.com/swiftype/SwiftypeTouch/blob/master/LICENSE) © [Elastic](https://github.com/elastic)

Thank you to all the [contributors](https://github.com/swiftype/SwiftypeTouch/graphs/contributors)!
