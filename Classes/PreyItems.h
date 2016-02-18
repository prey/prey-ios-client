//
//  PreyItems.h
//  Prey
//
//  Created by Javier Cala Uribe on 17/02/16.
//  Copyright © 2016 Fork Ltd. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, PreyPreferencesViewSection) {
    PreyPreferencesSectionInformation,
    PreyPreferencesSectionSettings,
    PreyPreferencesSectionAbout,
    PreyPreferencesSectionNumberToDataSourceDelegate
};

typedef NS_ENUM(NSInteger, PreyPreferencesSectionInformationItem) {
    PreyPreferencesSectionInformationCurrentLocation,
    PreyPreferencesSectionInformationGeofence,
    PreyPreferencesSectionInformationRecoveryStories,
    PreyPreferencesSectionInformationShareOnFacebook,
    PreyPreferencesSectionInformationShareOnTwitter,
    PreyPreferencesSectionInformationUpgradeToPro,
    PreyPreferencesSectionInformationNumberToDataSourceDelegate
};

typedef NS_ENUM(NSInteger, PreyPreferencesSectionSettingsItem) {
    PreyPreferencesSectionSettingsCamouglafeMode,
    PreyPreferencesSectionSettingsDetachDevice,
    PreyPreferencesSectionSettingsTouchID,
    PreyPreferencesSectionSettingsNumberToDataSourceDelegate
};

typedef NS_ENUM(NSInteger, PreyPreferencesSectionAboutItem) {
    PreyPreferencesSectionAboutVersion,
    PreyPreferencesSectionAboutHelp,
    PreyPreferencesSectionAboutTermService,
    PreyPreferencesSectionAboutPrivacyPolicy,
    PreyPreferencesSectionAboutNumberToDataSourceDelegate
};


NS_ASSUME_NONNULL_END
