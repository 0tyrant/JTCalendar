//
//  JTCalendar.m
//  JTCalendar
//
//  Created by Jonathan Tribouharet
//

#import "JTCalendar.h"

//#define NUMBER_PAGES_LOADED 5 // Must be the same in JTCalendarView, JTCalendarMenuView, JTCalendarContentView

@interface JTCalendar(){
    BOOL cacheLastWeekMode;
    NSUInteger cacheFirstWeekDay;
    int repositionPage;
}

@end

@implementation JTCalendar

- (instancetype)init
{
    self = [super init];
    if(!self){
        return nil;
    }
    
    self->_currentDate = [NSDate date];
    self->_calendarAppearance = [JTCalendarAppearance new];
    self->_dataCache = [JTCalendarDataCache new];
    self.dataCache.calendarManager = self;
    repositionPage = self.numberOfPageLoad / 2;
    
    return self;
}

// Bug in iOS
- (void)dealloc
{
    [self->_menuMonthsView setDelegate:nil];
    [self->_contentView setDelegate:nil];
}

- (void)setMenuMonthsView:(JTCalendarMenuView *)menuMonthsView
{
    [self->_menuMonthsView setDelegate:nil];
    [self->_menuMonthsView setCalendarManager:nil];
    
    self->_menuMonthsView = menuMonthsView;
    [self->_menuMonthsView setDelegate:self];
    [self->_menuMonthsView setCalendarManager:self];
    
    cacheLastWeekMode = self.calendarAppearance.isWeekMode;
    cacheFirstWeekDay = self.calendarAppearance.calendar.firstWeekday;
    
    [self.menuMonthsView setCurrentDate:self.currentDate];
    [self.menuMonthsView reloadAppearance];
}

- (void)setContentView:(JTCalendarContentView *)contentView
{
    [self->_contentView setDelegate:nil];
    [self->_contentView setCalendarManager:nil];
    
    self->_contentView = contentView;
    [self->_contentView setDelegate:self];
    [self->_contentView setCalendarManager:self];
    
    [self.contentView setCurrentDate:self.currentDate];
    [self.contentView reloadAppearance];
}

- (void)reloadData
{
    // Erase cache
    [self.dataCache reloadData];
    
    [self repositionViews];
    [self.contentView reloadData];
}

- (void)reloadAppearance
{
    [self.menuMonthsView reloadAppearance];
    [self.contentView reloadAppearance];
    
    if(cacheLastWeekMode != self.calendarAppearance.isWeekMode || cacheFirstWeekDay != self.calendarAppearance.calendar.firstWeekday){
        cacheLastWeekMode = self.calendarAppearance.isWeekMode;
        cacheFirstWeekDay = self.calendarAppearance.calendar.firstWeekday;
        
        if(self.calendarAppearance.focusSelectedDayChangeMode && self.currentDateSelected){
            [self setCurrentDate:self.currentDateSelected];
        }
        else{
            [self setCurrentDate:self.currentDate];
        }
    }
}

- (void)setCurrentDate:(NSDate *)currentDate
{
    NSAssert(currentDate, @"JTCalendar currentDate cannot be nil");

    self->_currentDate = currentDate;
    
    [self.menuMonthsView setCurrentDate:currentDate];
    [self.contentView setCurrentDate:currentDate];
    
    [self repositionViews];
    [self.contentView reloadData];
}

#pragma mark - UIScrollView delegate

- (void)scrollViewDidScroll:(UIScrollView *)sender
{
    if(self.calendarAppearance.isWeekMode){
        return;
    }
    
    CGFloat ratio = CGRectGetWidth(self.contentView.frame) / CGRectGetWidth(self.menuMonthsView.frame);
    if(isnan(ratio)){
        ratio = 1.;
    }
    ratio *= self.calendarAppearance.ratioContentMenu;
    
    if(sender == self.menuMonthsView && self.menuMonthsView.scrollEnabled){
        self.contentView.contentOffset = CGPointMake(sender.contentOffset.x * ratio, self.contentView.contentOffset.y);
    }
    else if(sender == self.contentView && self.contentView.scrollEnabled){
        self.menuMonthsView.contentOffset = CGPointMake(sender.contentOffset.x / ratio, self.menuMonthsView.contentOffset.y);
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if(scrollView == self.contentView){
        self.menuMonthsView.scrollEnabled = NO;
    }
    else if(scrollView == self.menuMonthsView){
        self.contentView.scrollEnabled = NO;
    }
}

// Use for scroll with scrollRectToVisible or setContentOffset
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self updatePage];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self updatePage];
}

- (void)updatePage
{
    CGFloat pageWidth = CGRectGetWidth(self.contentView.frame);
    CGFloat fractionalPage = self.contentView.contentOffset.x / pageWidth;
        
    int currentPage = roundf(fractionalPage);
    if (currentPage == (self.numberOfPageLoad / 2)){
        if(!self.calendarAppearance.isWeekMode){
            self.menuMonthsView.scrollEnabled = YES;
        }
        self.contentView.scrollEnabled = YES;
        return;
    }
    
    NSCalendar *calendar = self.calendarAppearance.calendar;
    NSDateComponents *dayComponent = [NSDateComponents new];
    
    dayComponent.month = 0;
    dayComponent.day = 0;
    
    if(!self.calendarAppearance.isWeekMode){
        dayComponent.month = currentPage - (self.numberOfPageLoad / 2);
    }
    else{
        dayComponent.day = 7 * (currentPage - (self.numberOfPageLoad / 2));
    }
    
    if(self.calendarAppearance.readFromRightToLeft){
        dayComponent.month *= -1;
        dayComponent.day *= -1;
    }
        
    NSDate *currentDate = [calendar dateByAddingComponents:dayComponent toDate:self.currentDate options:0];
    
    if ( [self dateAIsNoEalierThanDateB:[NSDate date] :currentDate]) {
        NSDateComponents *leftestDayComponent = [NSDateComponents new];
        leftestDayComponent.month = 4;
        leftestDayComponent.day = 0;
        NSDate *currentLeftestDate = [calendar dateByAddingComponents:leftestDayComponent toDate:self.leftestDate options: 0];
        if ([self dateAIsNoEalierThanDateB:currentDate :currentLeftestDate]) {
            repositionPage = self.numberOfPageLoad / 2;
            [self setCurrentDate:currentDate];
        } else {
            dayComponent.month = 1;
            currentDate = [calendar dateByAddingComponents:dayComponent toDate:currentDate options:0];
            if ([self isTwoDateInOneMonth:currentDate :currentLeftestDate]) {
                repositionPage = 1;
                [self setCurrentDate:currentDate];
            }
        }
    } else {
        dayComponent.month = -1;
        currentDate = [calendar dateByAddingComponents:dayComponent toDate:currentDate options:0];
        if ([self isTwoDateInOneMonth:currentDate :[NSDate date]]) {
            repositionPage = 3;
            [self setCurrentDate:currentDate];
        }
    }
    
    if(!self.calendarAppearance.isWeekMode){
        self.menuMonthsView.scrollEnabled = YES;
    }
    self.contentView.scrollEnabled = YES;
    
    if(currentPage < (self.numberOfPageLoad / 2)){
        if([self.dataSource respondsToSelector:@selector(calendarDidLoadPreviousPage)]){
            [self.dataSource calendarDidLoadPreviousPage];
        }
    }
    else if(currentPage > (self.numberOfPageLoad / 2)){
        if([self.dataSource respondsToSelector:@selector(calendarDidLoadNextPage)]){
            [self.dataSource calendarDidLoadNextPage];
        }
    }
}

- (void)repositionViews
{
    // Position to the middle page
    CGFloat pageWidth = CGRectGetWidth(self.contentView.frame);
    self.contentView.contentOffset = CGPointMake(pageWidth * (repositionPage), self.contentView.contentOffset.y);
    
    CGFloat menuPageWidth = CGRectGetWidth([self.menuMonthsView.subviews.firstObject frame]);
    self.menuMonthsView.contentOffset = CGPointMake(menuPageWidth * (repositionPage), self.menuMonthsView.contentOffset.y);
}

-(void)repositionViewsToToday {
    // Position to the middle page
    CGFloat pageWidth = CGRectGetWidth(self.contentView.frame);
    self.contentView.contentOffset = CGPointMake(pageWidth * ((self.numberOfPageLoad-1)), self.contentView.contentOffset.y);
    
    CGFloat menuPageWidth = CGRectGetWidth([self.menuMonthsView.subviews.firstObject frame]);
    self.menuMonthsView.contentOffset = CGPointMake(menuPageWidth * ((self.numberOfPageLoad -1)), self.menuMonthsView.contentOffset.y);
}

- (void)loadNextMonth
{
    [self loadNextPage];
}

- (void)loadPreviousMonth
{
    [self loadPreviousPage];
}

- (void)loadNextPage
{
    self.menuMonthsView.scrollEnabled = NO;
    
    CGRect frame = self.contentView.frame;
    frame.origin.x = frame.size.width * ((self.numberOfPageLoad / 2) + 1);
    frame.origin.y = 0;
    //[self.contentView scrollRectToVisible:frame animated:YES];
    CGPoint contentOffset = self.contentView.contentOffset;
    contentOffset.x += frame.size.width;
    if (contentOffset.x >= _contentView.contentSize.width) {
        return;
    }
    [self.contentView setContentOffset:contentOffset animated:YES];
}

- (void)loadPreviousPage
{
    self.menuMonthsView.scrollEnabled = NO;
    
    CGRect frame = self.contentView.frame;
    frame.origin.x = frame.size.width * ((self.numberOfPageLoad / 2) - 1);
    frame.origin.y = 0;
    //[self.contentView scrollRectToVisible:frame animated:YES];
    CGPoint contentOffset = self.contentView.contentOffset;
    contentOffset.x -= frame.size.width;
    if (contentOffset.x >= 0) {
       [self.contentView setContentOffset:contentOffset animated:YES];
    }
    
}

-(BOOL)isTwoDateInOneMonth:(NSDate *)dateA :(NSDate *)dateB {
    if ([self monthForDate:dateA] == [self monthForDate:dateB]) {
        return YES;
    } else {
        return NO;
    }
}

-(int)monthForDate:(NSDate *)date {
    NSCalendar *calendar = [[NSCalendar alloc]initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comps = [[NSDateComponents alloc]init];
    NSInteger unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekday | NSCalendarUnitHour | NSCalendarUnitMinute;
    comps = [calendar components:unitFlags fromDate:date];
    return comps.month;
}

-(int)yearForDate:(NSDate*)date {
    NSCalendar *calendar = [[NSCalendar alloc]initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comps = [[NSDateComponents alloc]init];
    NSInteger unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekday | NSCalendarUnitHour | NSCalendarUnitMinute;
    comps = [calendar components:unitFlags fromDate:date];
    return comps.year;
}

-(BOOL)dateAIsNoEalierThanDateB:(NSDate *)dateA :(NSDate *)dateB {
    if ([self yearForDate:dateA] > [self yearForDate:dateB]) {
        return YES;
    } else if ([self yearForDate:dateA] == [self yearForDate:dateB]) {
        if ([self monthForDate:dateA] >= [self monthForDate:dateB]) {
            return YES;
        } else {
            return NO;
        }
    } else {
        return NO;
    }
}
@end
