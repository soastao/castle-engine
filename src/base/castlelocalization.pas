{
  Copyright 2018 Benedikt Magnus.

  This file is part of "Castle Game Engine".

  "Castle Game Engine" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Castle Game Engine" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Localization system for handling localization.
  Use this in your games for easy localization.
  Note that this is not the only way to localize your Castle Game Engine games.
  You can as well use resourcestrings and standard FPC GetText unit directly,
  as shown in the example code in "examples/localization". }
unit CastleLocalization;

{$I castleconf.inc}
{$ifdef FPC}{$interfaces corba}{$endif}

interface

uses
  Classes, Generics.Collections,
  CastleSystemLanguage,
  CastleControls, CastleOnScreenMenu;

type
  { Dictionary (LocalizationID/TranslatedText as String/String) for storing all translated strings of the current language. }
  TLanguageDictionary = {$ifdef CASTLE_OBJFPC}specialize{$endif} TDictionary<String, String>;

  { Procedure of a file loader called by CastleLocalization to fill the language dictionary from a file stream. }
  TFileLoaderAction = procedure(const AFileStream: TStream; const ALanguageDictionary: TLanguageDictionary);
  { Dictionaty (FileExtension/FileLoaderAction as String/TFileLoaderAction) to connect the known file loaders with it's file extensions.}
  TFileLoaderDictionary = {$ifdef CASTLE_OBJFPC}specialize{$endif} TDictionary<String, TFileLoaderAction>;

  { Called by CastleLocalization to all subscribed procedures when a new language is set. }
  TOnLocalizationUpdatedEvent = procedure of object;
  TOnLocalizationUpdatedEventList = {$ifdef CASTLE_OBJFPC}specialize{$endif} TList<TOnLocalizationUpdatedEvent>;

  { Called by CastleLocalization to all subscribed components when a new language is set. }
  TOnUpdateLocalizationEvent = procedure(const ALocalizedText: String) of object;
  TOnUpdateLocalizationEventList = {$ifdef CASTLE_OBJFPC}specialize{$endif} TList<TOnUpdateLocalizationEvent>;

  { List (dictionary) for the localisation IDs of all subscribed components. }
  TLocalizationIDList = {$ifdef CASTLE_OBJFPC}specialize{$endif} TDictionary<TOnUpdateLocalizationEvent, String>;

type
  { Interface for custom user classes using the localisation.
    In contrast to ICastleLocalization, the class doesn't need to be an inheritant from TComponent.
    Useful for lightweight custom classes that need localisation and implement adding and removing from TCastleLocalization by themselves. }
  ICastleLocalizationCustom = interface
    ['{d4cdfeb4-32c9-2409-07cc-00aa862851a4}']
    procedure OnUpdateLocalization(const ALocalizedText: String);
  end;

  { Interface for all user components using the localisation.
    Allows to automatically localise and adjust a TComponent to language changes. }
  ICastleLocalization = interface (ICastleLocalizationCustom)
    ['{4fa1cb64-f806-2409-07cc-ca1a77e5c0e4}']
    procedure FreeNotification(AComponent: TComponent);
  end;

type
  { Main comonent for localisation, singleton as Localization. }
  TCastleLocalization = class (TComponent)
    protected
      FLanguageDictionary: TLanguageDictionary;
      FLanguageURL: String;
      FFileLoaderDictionary: TFileLoaderDictionary;
      FLocalizationIDList: TLocalizationIDList;
      FOnUpdateLocalizationEventList: TOnUpdateLocalizationEventList;
      FOnLocalizationUpdatedEventList: TOnLocalizationUpdatedEventList;
      function Get(AKey: String): String;
      procedure LoadLanguage(const ALanguageURL: String);
      procedure Notification(AComponent: TComponent; Operation: TOperation); override;
      function AddOrSet(AOnUpdateLocalizationEvent: TOnUpdateLocalizationEvent; const ALocalizationID: String): Boolean; overload; inline;
      procedure RemoveFromUpdateList(AOnUpdateLocalizationEvent: TOnUpdateLocalizationEvent); inline;
    public
      constructor Create(AOwner: TComponent); override;
      destructor Destroy; override;
      { Returns the current system language as language code.
        For example: en, de, pl }
      function SystemLanguage(const ADefaultLanguage: String = SystemDefaultLanguage): String; inline;
      { Returns the current system local as langauge code and local info.
        For example: en_US, en_GB, es_ES }
      function SystemLocal(const ADefaultLocal: String = SystemDefaultLocal): String; inline;
      { Adds a new component to the automised localisation list or, if it already is listed, updates it's localisation ID.
        If ALocalizationID is empty, the element is removed from the localisation list. }
      procedure AddOrSet(ALocalizationComponent: ICastleLocalization; const ALocalizationID: String); overload;
      { Adds a new custom localisation class to the automised localisation list or, if it already is listed, updates it's localisation ID.
        If ALocalizationID is empty, the element is removed from the localisation list. }
      procedure AddOrSet(ALocalizationComponent: ICastleLocalizationCustom; const ALocalizationID: String); overload;
    public
      property Items[AKey: String]: String read Get; default;
      { The URL to the language file that shall be loaded for localisation. }
      property LanguageURL: String read FLanguageURL write LoadLanguage;
      { A list (dictionary) of file loaders.
        You can use this to add custom file loader for new file extensions or overwrite existing ones to change the file format. }
      property FileLoader: TFileLoaderDictionary read FFileLoaderDictionary;
      { A list of subscribed procedures of that each will be called when the langauge changes.
        You can add a procedure to this to localise images or such that is no descendent of TComponent. }
      property OnUpdateLocalization: TOnLocalizationUpdatedEventList read FOnLocalizationUpdatedEventList;
  end;

var
  { Singleton for TCastleLocalization. }
  Localization: TCastleLocalization;

{$define read_interface}
{$I castlelocalization_castlecore.inc}
{$undef read_interface}

implementation

uses
  SysUtils,
  CastleURIUtils, CastleUtils, CastleDownload,
  CastleLocalizationFileLoader;

{$define read_implementation}
{$I castlelocalization_castlecore.inc}
{$undef read_implementation}

//////////////////////////
//Constructor/Destructor//
//////////////////////////

constructor TCastleLocalization.Create(AOwner: TComponent);
begin
  inherited;

  FLanguageDictionary := TLanguageDictionary.Create;
  FFileLoaderDictionary := TFileLoaderDictionary.Create;
  FLocalizationIDList := TLocalizationIDList.Create;
  FOnLocalizationUpdatedEventList := TOnLocalizationUpdatedEventList.Create;
  FOnUpdateLocalizationEventList := TOnUpdateLocalizationEventList.Create;
end;

destructor TCastleLocalization.Destroy;
begin
  FreeAndNil(FOnUpdateLocalizationEventList);
  FreeAndNil(FOnLocalizationUpdatedEventList);
  FreeAndNil(FLocalizationIDList);
  FreeAndNil(FFileLoaderDictionary);
  FreeAndNil(FLanguageDictionary);

  inherited;
end;

/////////////////////
//Private/Protected//
/////////////////////

function TCastleLocalization.Get(AKey: String): String;
begin
  if not FLanguageDictionary.TryGetValue(AKey, Result) then
    Result := AKey; //When no translation is found, return the key.
end;

procedure TCastleLocalization.LoadLanguage(const ALanguageURL: String);
var
  FileLoaderAction: TFileLoaderAction;
  Stream: TStream;
  LocalizedText: String;
  OnUpdateLocalizationEvent: TOnUpdateLocalizationEvent;
  OnLocalizationUpdatedEvent: TOnLocalizationUpdatedEvent;
begin
  if FLanguageURL = ALanguageURL then Exit;
  FLanguageURL := ALanguageURL;

  FLanguageDictionary.Clear;

  if ALanguageURL = '' then Exit; //If there's no language XML file, then that's it, no more localisation.

  FFileLoaderDictionary.TryGetValue(ExtractFileExt(ALanguageURL), FileLoaderAction);
  Check(Assigned(FileLoaderAction), 'There is no file loader associated with the extension of the given file.');

  Stream := Download(AbsoluteURI(ALanguageURL));
  try
    FileLoaderAction(Stream, FLanguageDictionary);
  finally
    Stream.Free;
  end;

  //Tell every registered object to update its localisation:
  for OnUpdateLocalizationEvent in FOnUpdateLocalizationEventList do
  begin
    FLocalizationIDList.TryGetValue(OnUpdateLocalizationEvent, LocalizedText);
    OnUpdateLocalizationEvent(Items[LocalizedText]);
  end;

  //Tell every custom object to update its localisation:
  for OnLocalizationUpdatedEvent in FOnLocalizationUpdatedEventList do
    OnLocalizationUpdatedEvent();
end;

{$NOTES OFF} //If not disabled, it will say LCastleLocalizationComponent was assigned but never used... but it IS used...
procedure TCastleLocalization.Notification(AComponent: TComponent; Operation: TOperation);
var
  LCastleLocalizationComponent: ICastleLocalization;
begin
  if Operation = opRemove then
  begin
    AComponent.RemoveFreeNotification(Self);

    LCastleLocalizationComponent := AComponent as ICastleLocalization;
    RemoveFromUpdateList(@LCastleLocalizationComponent.OnUpdateLocalization);
  end;
end;
{$NOTES ON}

function TCastleLocalization.AddOrSet(AOnUpdateLocalizationEvent: TOnUpdateLocalizationEvent; const ALocalizationID: String): Boolean;
begin
  Result := not FLocalizationIDList.ContainsKey(AOnUpdateLocalizationEvent);
  FLocalizationIDList.AddOrSetValue(AOnUpdateLocalizationEvent, ALocalizationID);

  if Result then
    FOnUpdateLocalizationEventList.Add(AOnUpdateLocalizationEvent);
end;

procedure RemoveFromUpdateList(AOnUpdateLocalizationEvent: TOnUpdateLocalizationEvent);
begin
  FOnUpdateLocalizationEventList.Remove(@ALocalizationComponent.OnUpdateLocalization);
  FLocalizationIDList.Remove(@ALocalizationComponent.OnUpdateLocalization);
end;

//////////////
////Public////
//////////////

function TCastleLocalization.SystemLanguage(const ADefaultLanguage: String = SystemDefaultLanguage): String;
begin
  Result := CastleSystemLanguage.SystemLanguage(ADefaultLanguage);
end;

function TCastleLocalization.SystemLocal(const ADefaultLocal: String = SystemDefaultLocal): String;
begin
  Result := CastleSystemLanguage.SystemLocal(ADefaultLocal);
end;

procedure TCastleLocalization.AddOrSet(ALocalizationComponent: ICastleLocalization; const ALocalizationID: String);
begin
  if ALocalizationID = '' then
    RemoveFromUpdateList(@ALocalizationComponent.OnUpdateLocalization)
  else
  begin
    if AddOrSet(@ALocalizationComponent.OnUpdateLocalization, ALocalizationID) then
      ALocalizationComponent.FreeNotification(Self);

    ALocalizationComponent.OnUpdateLocalization(Items[ALocalizationID]);
  end;
end;

procedure TCastleLocalization.AddOrSet(ALocalizationComponent: ICastleLocalizationCustom; const ALocalizationID: String);
begin
  if ALocalizationID = '' then
    RemoveFromUpdateList(@ALocalizationComponent.OnUpdateLocalization)
  else
  begin
    AddOrSet(@ALocalizationComponent.OnUpdateLocalization, ALocalizationID);

    ALocalizationComponent.OnUpdateLocalization(Items[ALocalizationID]);
  end;
end;

initialization
  Localization := TCastleLocalization.Create(nil);
  ActivateAllFileLoader;

finalization
  FreeAndNil(Localization);

end.