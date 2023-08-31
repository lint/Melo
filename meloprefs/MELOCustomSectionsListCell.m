
#import "MELOCustomSectionsListCell.h"
#import "MELOCustomSectionsListController.h"
#import <Preferences/PSSpecifier.h>

@implementation MELOCustomSectionsListCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self) {
        _titleTextField = [[UITextField alloc] init];
        _titleTextField.delegate = self;
        _titleTextField.placeholder = @"Section Title (Required)";
        _titleTextField.font = [UIFont systemFontOfSize:14];
        [self.contentView addSubview:_titleTextField];

        _subtitleTextField = [[UITextField alloc] init];
        _subtitleTextField.delegate = self;
        _subtitleTextField.placeholder = @"Subtitle (Optional)";
        _subtitleTextField.font = [UIFont systemFontOfSize:14];
        [self.contentView addSubview:_subtitleTextField];

        _verticalSeparatorView = [[UIView alloc] init];
        _verticalSeparatorView.backgroundColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:0.5];
        [self.contentView addSubview:_verticalSeparatorView];

        [self setShouldHideTitle:YES];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSpecifier) name:UITextFieldTextDidChangeNotification object:_titleTextField];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSpecifier) name:UITextFieldTextDidChangeNotification object:_subtitleTextField];
    }

    return self;
}

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

- (void)setSpecifier:(PSSpecifier *)arg1 {
    [super setSpecifier:arg1];

    NSDictionary *properties = arg1.properties;

    _titleTextField.text = properties[@"customSectionTitle"];
    _subtitleTextField.text = properties[@"customSectionSubtitle"];
}

- (void)updateSpecifier {

    NSMutableDictionary *properties = [self specifier].properties;

    properties[@"customSectionTitle"] = _titleTextField.text;
    properties[@"customSectionSubtitle"] = _subtitleTextField.text;

    //[self saveData];
    MELOCustomSectionsListController *controller = (MELOCustomSectionsListController *)[[self _tableView] dataSource];
    [controller setNeedsSave];
}

- (void)saveData {
    MELOCustomSectionsListController *controller = (MELOCustomSectionsListController *)[[self _tableView] dataSource];
    [controller saveData];
}

- (void)textFieldDidEndEditing:(UITextField *)arg1 {
    [self updateSpecifier];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat contentViewWidth = self.contentView.frame.size.width;
    CGFloat cellHeight = self.frame.size.height;

    CGFloat edgeInset = 15;
    CGFloat separatorWidth = 2;

    CGFloat textFieldWidth = contentViewWidth / 2 - edgeInset * 2 - separatorWidth;
    CGFloat textFieldHeight = 18.5;

    CGRect titleFrame = CGRectMake(edgeInset, ceil((cellHeight - textFieldHeight) / 2), textFieldWidth, textFieldHeight);
    CGRect subtitleFrame = CGRectMake((contentViewWidth + separatorWidth) / 2 + edgeInset, ceil((cellHeight - textFieldHeight) / 2), textFieldWidth, textFieldHeight);
    CGRect separatorFrame = CGRectMake((contentViewWidth - separatorWidth) / 2, (cellHeight - 24) / 2, separatorWidth, 24);

    _titleTextField.frame = titleFrame;
    _subtitleTextField.frame = subtitleFrame;
    _verticalSeparatorView.frame = separatorFrame;
}

@end
