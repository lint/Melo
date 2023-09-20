
#import "MELOCustomSectionsListCell.h"
#import "MELOCustomSectionsListController.h"
#import <Preferences/PSSpecifier.h>

@implementation MELOCustomSectionsListCell

// default initializer
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self) {

        // create main title text field
        _titleTextField = [[UITextField alloc] init];
        _titleTextField.delegate = self;
        _titleTextField.placeholder = @"Title";
        _titleTextField.font = [UIFont systemFontOfSize:14];
        [self.contentView addSubview:_titleTextField];

        // create subtitle text field
        _subtitleTextField = [[UITextField alloc] init];
        _subtitleTextField.delegate = self;
        _subtitleTextField.placeholder = @"Subtitle";
        _subtitleTextField.font = [UIFont systemFontOfSize:14];
        [self.contentView addSubview:_subtitleTextField];

        // create UIView which separates the title and subtitle
        _verticalSeparatorView = [[UIView alloc] init];
        _verticalSeparatorView.backgroundColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:0.5];
        [self.contentView addSubview:_verticalSeparatorView];

        // i believe this hides the main PSTableCell title
        [self setShouldHideTitle:YES];

        // set a handler for whenever the text fields change
        // [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSpecifier) name:UITextFieldTextDidChangeNotification object:_titleTextField];
        // [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSpecifier) name:UITextFieldTextDidChangeNotification object:_subtitleTextField];
    }

    return self;
}

// initializer with a given title and subtitle
- (id)initWithTitle:(NSString *)arg1 subtitle:(NSString *)arg2 {
    self = [self initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MELOCustomSectionsListCell"];

    if (self) {
        _sectionTitle = arg1;
        _sectionSubtitle = arg2;
        _titleTextField.text = arg1;
        _subtitleTextField.text = arg2;
    }

    return self;
}

// sets the cell's specifier value
- (void)setSpecifier:(PSSpecifier *)arg1 {
    [super setSpecifier:arg1];

    NSDictionary *properties = arg1.properties;

    // update the text fields with the specifier contents
    _titleTextField.text = properties[@"customSectionTitle"];
    _subtitleTextField.text = properties[@"customSectionSubtitle"];
}

// handler for when the text field interaction finishes
- (void)textFieldDidEndEditing:(UITextField *)arg1 {
    [self updateSpecifier];
}

// clears out custom text in the text field and the specifier
- (void)clearText {

    NSMutableDictionary *properties = [self specifier].properties;
    properties[@"customSectionTitle"] = @"";
    properties[@"customSectionSubtitle"] = @"";

    _titleTextField.text = @"";
    _subtitleTextField.text = @"";
}

// updates the specifier with the current text field contents
- (void)updateSpecifier {

    NSMutableDictionary *properties = [self specifier].properties;
    properties[@"customSectionTitle"] = _titleTextField.text;
    properties[@"customSectionSubtitle"] = _subtitleTextField.text;

    // save the changes to preferences file
    [self saveData];
}

// save changes to preferences file by using the controller
- (void)saveData {
    MELOCustomSectionsListController *controller = (MELOCustomSectionsListController *)[[self _tableView] dataSource];
    [controller saveData];
}

// setup the display for any subviews
- (void)layoutSubviews {
    [super layoutSubviews];

    /* set frames of text views and separator */

    CGFloat contentViewWidth = self.contentView.frame.size.width;
    CGFloat cellHeight = self.frame.size.height;

    CGFloat separatorWidth = 2;
    CGFloat edgeInset = [UIView pu_layoutMarginWidthForCurrentScreenSize]; // = 15;
    CGFloat textFieldHeight = 18.5;
    CGFloat textFieldWidth = contentViewWidth / 2 - edgeInset * 2 - separatorWidth;

    CGRect titleFrame = CGRectMake(edgeInset, ceil((cellHeight - textFieldHeight) / 2), textFieldWidth, textFieldHeight);
    CGRect subtitleFrame = CGRectMake((contentViewWidth + separatorWidth) / 2 + edgeInset, ceil((cellHeight - textFieldHeight) / 2), textFieldWidth, textFieldHeight);
    CGRect separatorFrame = CGRectMake((contentViewWidth - separatorWidth) / 2, (cellHeight - 24) / 2, separatorWidth, 24);

    _titleTextField.frame = titleFrame;
    _subtitleTextField.frame = subtitleFrame;
    _verticalSeparatorView.frame = separatorFrame;
}

@end
