{ -*- buffer-read-only: t -*-

  Copyright 2015-2017 Michalis Kamburelis.

  This file is part of "Castle Game Engine".

  "Castle Game Engine" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Castle Game Engine" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Automatically generated X3D node class helpers.
  Do not edit manually, instead regenerate using
  castle_game_engine/src/x3d/doc/generate_x3d_nodes_to_pascal.lpr . }

{$ifdef read_interface}

  private
    function GetAddress: string;
    procedure SetAddress(const Value: string);
    function GetApplicationID: Integer;
    procedure SetApplicationID(const Value: Integer);
    function GetArticulationParameterCount: Integer;
    procedure SetArticulationParameterCount(const Value: Integer);
    function GetCenter: TVector3Single;
    procedure SetCenter(const Value: TVector3Single);
    function GetCollisionType: Integer;
    procedure SetCollisionType(const Value: Integer);
    function GetDeadReckoning: Integer;
    procedure SetDeadReckoning(const Value: Integer);
    function GetDetonationLocation: TVector3Single;
    procedure SetDetonationLocation(const Value: TVector3Single);
    function GetDetonationRelativeLocation: TVector3Single;
    procedure SetDetonationRelativeLocation(const Value: TVector3Single);
    function GetDetonationResult: Integer;
    procedure SetDetonationResult(const Value: Integer);
    function GetEnabled: boolean;
    procedure SetEnabled(const Value: boolean);
    function GetEntityCategory: Integer;
    procedure SetEntityCategory(const Value: Integer);
    function GetEntityCountry: Integer;
    procedure SetEntityCountry(const Value: Integer);
    function GetEntityDomain: Integer;
    procedure SetEntityDomain(const Value: Integer);
    function GetEntityExtra: Integer;
    procedure SetEntityExtra(const Value: Integer);
    function GetEntityID: Integer;
    procedure SetEntityID(const Value: Integer);
    function GetEntityKind: Integer;
    procedure SetEntityKind(const Value: Integer);
    function GetEntitySpecific: Integer;
    procedure SetEntitySpecific(const Value: Integer);
    function GetEntitySubCategory: Integer;
    procedure SetEntitySubCategory(const Value: Integer);
    function GetEventApplicationID: Integer;
    procedure SetEventApplicationID(const Value: Integer);
    function GetEventEntityID: Integer;
    procedure SetEventEntityID(const Value: Integer);
    function GetEventNumber: Integer;
    procedure SetEventNumber(const Value: Integer);
    function GetEventSiteID: Integer;
    procedure SetEventSiteID(const Value: Integer);
    function GetFired1: boolean;
    procedure SetFired1(const Value: boolean);
    function GetFired2: boolean;
    procedure SetFired2(const Value: boolean);
    function GetFireMissionIndex: Integer;
    procedure SetFireMissionIndex(const Value: Integer);
    function GetFiringRange: Single;
    procedure SetFiringRange(const Value: Single);
    function GetFiringRate: Integer;
    procedure SetFiringRate(const Value: Integer);
    function GetForceID: Integer;
    procedure SetForceID(const Value: Integer);
    function GetFuse: Integer;
    procedure SetFuse(const Value: Integer);
    function GetLinearVelocity: TVector3Single;
    procedure SetLinearVelocity(const Value: TVector3Single);
    function GetLinearAcceleration: TVector3Single;
    procedure SetLinearAcceleration(const Value: TVector3Single);
    function GetMarking: string;
    procedure SetMarking(const Value: string);
    function GetMulticastRelayHost: string;
    procedure SetMulticastRelayHost(const Value: string);
    function GetMulticastRelayPort: Integer;
    procedure SetMulticastRelayPort(const Value: Integer);
    function GetMunitionApplicationID: Integer;
    procedure SetMunitionApplicationID(const Value: Integer);
    function GetMunitionEndPoint: TVector3Single;
    procedure SetMunitionEndPoint(const Value: TVector3Single);
    function GetMunitionEntityID: Integer;
    procedure SetMunitionEntityID(const Value: Integer);
    function GetMunitionQuantity: Integer;
    procedure SetMunitionQuantity(const Value: Integer);
    function GetMunitionSiteID: Integer;
    procedure SetMunitionSiteID(const Value: Integer);
    function GetMunitionStartPoint: TVector3Single;
    procedure SetMunitionStartPoint(const Value: TVector3Single);
    function GetPort: Integer;
    procedure SetPort(const Value: Integer);
    function GetReadInterval: TFloatTime;
    procedure SetReadInterval(const Value: TFloatTime);
    function GetRotation: TVector4Single;
    procedure SetRotation(const Value: TVector4Single);
    function GetScale: TVector3Single;
    procedure SetScale(const Value: TVector3Single);
    function GetScaleOrientation: TVector4Single;
    procedure SetScaleOrientation(const Value: TVector4Single);
    function GetSiteID: Integer;
    procedure SetSiteID(const Value: Integer);
    function GetTranslation: TVector3Single;
    procedure SetTranslation(const Value: TVector3Single);
    function GetWarhead: Integer;
    procedure SetWarhead(const Value: Integer);
    function GetWriteInterval: TFloatTime;
    procedure SetWriteInterval(const Value: TFloatTime);
    function GetRtpHeaderExpected: boolean;
    procedure SetRtpHeaderExpected(const Value: boolean);
  public
    property Address: string read GetAddress write SetAddress;
    property ApplicationID: Integer read GetApplicationID write SetApplicationID;
    property ArticulationParameterCount: Integer read GetArticulationParameterCount write SetArticulationParameterCount;
    property Center: TVector3Single read GetCenter write SetCenter;
    property CollisionType: Integer read GetCollisionType write SetCollisionType;
    property DeadReckoning: Integer read GetDeadReckoning write SetDeadReckoning;
    property DetonationLocation: TVector3Single read GetDetonationLocation write SetDetonationLocation;
    property DetonationRelativeLocation: TVector3Single read GetDetonationRelativeLocation write SetDetonationRelativeLocation;
    property DetonationResult: Integer read GetDetonationResult write SetDetonationResult;
    property Enabled: boolean read GetEnabled write SetEnabled;
    property EntityCategory: Integer read GetEntityCategory write SetEntityCategory;
    property EntityCountry: Integer read GetEntityCountry write SetEntityCountry;
    property EntityDomain: Integer read GetEntityDomain write SetEntityDomain;
    property EntityExtra: Integer read GetEntityExtra write SetEntityExtra;
    property EntityID: Integer read GetEntityID write SetEntityID;
    property EntityKind: Integer read GetEntityKind write SetEntityKind;
    property EntitySpecific: Integer read GetEntitySpecific write SetEntitySpecific;
    property EntitySubCategory: Integer read GetEntitySubCategory write SetEntitySubCategory;
    property EventApplicationID: Integer read GetEventApplicationID write SetEventApplicationID;
    property EventEntityID: Integer read GetEventEntityID write SetEventEntityID;
    property EventNumber: Integer read GetEventNumber write SetEventNumber;
    property EventSiteID: Integer read GetEventSiteID write SetEventSiteID;
    property Fired1: boolean read GetFired1 write SetFired1;
    property Fired2: boolean read GetFired2 write SetFired2;
    property FireMissionIndex: Integer read GetFireMissionIndex write SetFireMissionIndex;
    property FiringRange: Single read GetFiringRange write SetFiringRange;
    property FiringRate: Integer read GetFiringRate write SetFiringRate;
    property ForceID: Integer read GetForceID write SetForceID;
    property Fuse: Integer read GetFuse write SetFuse;
    property LinearVelocity: TVector3Single read GetLinearVelocity write SetLinearVelocity;
    property LinearAcceleration: TVector3Single read GetLinearAcceleration write SetLinearAcceleration;
    property Marking: string read GetMarking write SetMarking;
    property MulticastRelayHost: string read GetMulticastRelayHost write SetMulticastRelayHost;
    property MulticastRelayPort: Integer read GetMulticastRelayPort write SetMulticastRelayPort;
    property MunitionApplicationID: Integer read GetMunitionApplicationID write SetMunitionApplicationID;
    property MunitionEndPoint: TVector3Single read GetMunitionEndPoint write SetMunitionEndPoint;
    property MunitionEntityID: Integer read GetMunitionEntityID write SetMunitionEntityID;
    property MunitionQuantity: Integer read GetMunitionQuantity write SetMunitionQuantity;
    property MunitionSiteID: Integer read GetMunitionSiteID write SetMunitionSiteID;
    property MunitionStartPoint: TVector3Single read GetMunitionStartPoint write SetMunitionStartPoint;
    property Port: Integer read GetPort write SetPort;
    property ReadInterval: TFloatTime read GetReadInterval write SetReadInterval;
    property Rotation: TVector4Single read GetRotation write SetRotation;
    property Scale: TVector3Single read GetScale write SetScale;
    property ScaleOrientation: TVector4Single read GetScaleOrientation write SetScaleOrientation;
    property SiteID: Integer read GetSiteID write SetSiteID;
    property Translation: TVector3Single read GetTranslation write SetTranslation;
    property Warhead: Integer read GetWarhead write SetWarhead;
    property WriteInterval: TFloatTime read GetWriteInterval write SetWriteInterval;
    property RtpHeaderExpected: boolean read GetRtpHeaderExpected write SetRtpHeaderExpected;

{$endif read_interface}

{$ifdef read_implementation}

{ TEspduTransformNode ----------------------------------------------- }

function TEspduTransformNode.GetAddress: string;
begin
  Result := FdAddress.Value;
end;

procedure TEspduTransformNode.SetAddress(const Value: string);
begin
  FdAddress.Send(Value);
end;

function TEspduTransformNode.GetApplicationID: Integer;
begin
  Result := FdApplicationID.Value;
end;

procedure TEspduTransformNode.SetApplicationID(const Value: Integer);
begin
  FdApplicationID.Send(Value);
end;

function TEspduTransformNode.GetArticulationParameterCount: Integer;
begin
  Result := FdArticulationParameterCount.Value;
end;

procedure TEspduTransformNode.SetArticulationParameterCount(const Value: Integer);
begin
  FdArticulationParameterCount.Send(Value);
end;

function TEspduTransformNode.GetCenter: TVector3Single;
begin
  Result := FdCenter.Value;
end;

procedure TEspduTransformNode.SetCenter(const Value: TVector3Single);
begin
  FdCenter.Send(Value);
end;

function TEspduTransformNode.GetCollisionType: Integer;
begin
  Result := FdCollisionType.Value;
end;

procedure TEspduTransformNode.SetCollisionType(const Value: Integer);
begin
  FdCollisionType.Send(Value);
end;

function TEspduTransformNode.GetDeadReckoning: Integer;
begin
  Result := FdDeadReckoning.Value;
end;

procedure TEspduTransformNode.SetDeadReckoning(const Value: Integer);
begin
  FdDeadReckoning.Send(Value);
end;

function TEspduTransformNode.GetDetonationLocation: TVector3Single;
begin
  Result := FdDetonationLocation.Value;
end;

procedure TEspduTransformNode.SetDetonationLocation(const Value: TVector3Single);
begin
  FdDetonationLocation.Send(Value);
end;

function TEspduTransformNode.GetDetonationRelativeLocation: TVector3Single;
begin
  Result := FdDetonationRelativeLocation.Value;
end;

procedure TEspduTransformNode.SetDetonationRelativeLocation(const Value: TVector3Single);
begin
  FdDetonationRelativeLocation.Send(Value);
end;

function TEspduTransformNode.GetDetonationResult: Integer;
begin
  Result := FdDetonationResult.Value;
end;

procedure TEspduTransformNode.SetDetonationResult(const Value: Integer);
begin
  FdDetonationResult.Send(Value);
end;

function TEspduTransformNode.GetEnabled: boolean;
begin
  Result := FdEnabled.Value;
end;

procedure TEspduTransformNode.SetEnabled(const Value: boolean);
begin
  FdEnabled.Send(Value);
end;

function TEspduTransformNode.GetEntityCategory: Integer;
begin
  Result := FdEntityCategory.Value;
end;

procedure TEspduTransformNode.SetEntityCategory(const Value: Integer);
begin
  FdEntityCategory.Send(Value);
end;

function TEspduTransformNode.GetEntityCountry: Integer;
begin
  Result := FdEntityCountry.Value;
end;

procedure TEspduTransformNode.SetEntityCountry(const Value: Integer);
begin
  FdEntityCountry.Send(Value);
end;

function TEspduTransformNode.GetEntityDomain: Integer;
begin
  Result := FdEntityDomain.Value;
end;

procedure TEspduTransformNode.SetEntityDomain(const Value: Integer);
begin
  FdEntityDomain.Send(Value);
end;

function TEspduTransformNode.GetEntityExtra: Integer;
begin
  Result := FdEntityExtra.Value;
end;

procedure TEspduTransformNode.SetEntityExtra(const Value: Integer);
begin
  FdEntityExtra.Send(Value);
end;

function TEspduTransformNode.GetEntityID: Integer;
begin
  Result := FdEntityID.Value;
end;

procedure TEspduTransformNode.SetEntityID(const Value: Integer);
begin
  FdEntityID.Send(Value);
end;

function TEspduTransformNode.GetEntityKind: Integer;
begin
  Result := FdEntityKind.Value;
end;

procedure TEspduTransformNode.SetEntityKind(const Value: Integer);
begin
  FdEntityKind.Send(Value);
end;

function TEspduTransformNode.GetEntitySpecific: Integer;
begin
  Result := FdEntitySpecific.Value;
end;

procedure TEspduTransformNode.SetEntitySpecific(const Value: Integer);
begin
  FdEntitySpecific.Send(Value);
end;

function TEspduTransformNode.GetEntitySubCategory: Integer;
begin
  Result := FdEntitySubCategory.Value;
end;

procedure TEspduTransformNode.SetEntitySubCategory(const Value: Integer);
begin
  FdEntitySubCategory.Send(Value);
end;

function TEspduTransformNode.GetEventApplicationID: Integer;
begin
  Result := FdEventApplicationID.Value;
end;

procedure TEspduTransformNode.SetEventApplicationID(const Value: Integer);
begin
  FdEventApplicationID.Send(Value);
end;

function TEspduTransformNode.GetEventEntityID: Integer;
begin
  Result := FdEventEntityID.Value;
end;

procedure TEspduTransformNode.SetEventEntityID(const Value: Integer);
begin
  FdEventEntityID.Send(Value);
end;

function TEspduTransformNode.GetEventNumber: Integer;
begin
  Result := FdEventNumber.Value;
end;

procedure TEspduTransformNode.SetEventNumber(const Value: Integer);
begin
  FdEventNumber.Send(Value);
end;

function TEspduTransformNode.GetEventSiteID: Integer;
begin
  Result := FdEventSiteID.Value;
end;

procedure TEspduTransformNode.SetEventSiteID(const Value: Integer);
begin
  FdEventSiteID.Send(Value);
end;

function TEspduTransformNode.GetFired1: boolean;
begin
  Result := FdFired1.Value;
end;

procedure TEspduTransformNode.SetFired1(const Value: boolean);
begin
  FdFired1.Send(Value);
end;

function TEspduTransformNode.GetFired2: boolean;
begin
  Result := FdFired2.Value;
end;

procedure TEspduTransformNode.SetFired2(const Value: boolean);
begin
  FdFired2.Send(Value);
end;

function TEspduTransformNode.GetFireMissionIndex: Integer;
begin
  Result := FdFireMissionIndex.Value;
end;

procedure TEspduTransformNode.SetFireMissionIndex(const Value: Integer);
begin
  FdFireMissionIndex.Send(Value);
end;

function TEspduTransformNode.GetFiringRange: Single;
begin
  Result := FdFiringRange.Value;
end;

procedure TEspduTransformNode.SetFiringRange(const Value: Single);
begin
  FdFiringRange.Send(Value);
end;

function TEspduTransformNode.GetFiringRate: Integer;
begin
  Result := FdFiringRate.Value;
end;

procedure TEspduTransformNode.SetFiringRate(const Value: Integer);
begin
  FdFiringRate.Send(Value);
end;

function TEspduTransformNode.GetForceID: Integer;
begin
  Result := FdForceID.Value;
end;

procedure TEspduTransformNode.SetForceID(const Value: Integer);
begin
  FdForceID.Send(Value);
end;

function TEspduTransformNode.GetFuse: Integer;
begin
  Result := FdFuse.Value;
end;

procedure TEspduTransformNode.SetFuse(const Value: Integer);
begin
  FdFuse.Send(Value);
end;

function TEspduTransformNode.GetLinearVelocity: TVector3Single;
begin
  Result := FdLinearVelocity.Value;
end;

procedure TEspduTransformNode.SetLinearVelocity(const Value: TVector3Single);
begin
  FdLinearVelocity.Send(Value);
end;

function TEspduTransformNode.GetLinearAcceleration: TVector3Single;
begin
  Result := FdLinearAcceleration.Value;
end;

procedure TEspduTransformNode.SetLinearAcceleration(const Value: TVector3Single);
begin
  FdLinearAcceleration.Send(Value);
end;

function TEspduTransformNode.GetMarking: string;
begin
  Result := FdMarking.Value;
end;

procedure TEspduTransformNode.SetMarking(const Value: string);
begin
  FdMarking.Send(Value);
end;

function TEspduTransformNode.GetMulticastRelayHost: string;
begin
  Result := FdMulticastRelayHost.Value;
end;

procedure TEspduTransformNode.SetMulticastRelayHost(const Value: string);
begin
  FdMulticastRelayHost.Send(Value);
end;

function TEspduTransformNode.GetMulticastRelayPort: Integer;
begin
  Result := FdMulticastRelayPort.Value;
end;

procedure TEspduTransformNode.SetMulticastRelayPort(const Value: Integer);
begin
  FdMulticastRelayPort.Send(Value);
end;

function TEspduTransformNode.GetMunitionApplicationID: Integer;
begin
  Result := FdMunitionApplicationID.Value;
end;

procedure TEspduTransformNode.SetMunitionApplicationID(const Value: Integer);
begin
  FdMunitionApplicationID.Send(Value);
end;

function TEspduTransformNode.GetMunitionEndPoint: TVector3Single;
begin
  Result := FdMunitionEndPoint.Value;
end;

procedure TEspduTransformNode.SetMunitionEndPoint(const Value: TVector3Single);
begin
  FdMunitionEndPoint.Send(Value);
end;

function TEspduTransformNode.GetMunitionEntityID: Integer;
begin
  Result := FdMunitionEntityID.Value;
end;

procedure TEspduTransformNode.SetMunitionEntityID(const Value: Integer);
begin
  FdMunitionEntityID.Send(Value);
end;

function TEspduTransformNode.GetMunitionQuantity: Integer;
begin
  Result := FdMunitionQuantity.Value;
end;

procedure TEspduTransformNode.SetMunitionQuantity(const Value: Integer);
begin
  FdMunitionQuantity.Send(Value);
end;

function TEspduTransformNode.GetMunitionSiteID: Integer;
begin
  Result := FdMunitionSiteID.Value;
end;

procedure TEspduTransformNode.SetMunitionSiteID(const Value: Integer);
begin
  FdMunitionSiteID.Send(Value);
end;

function TEspduTransformNode.GetMunitionStartPoint: TVector3Single;
begin
  Result := FdMunitionStartPoint.Value;
end;

procedure TEspduTransformNode.SetMunitionStartPoint(const Value: TVector3Single);
begin
  FdMunitionStartPoint.Send(Value);
end;

function TEspduTransformNode.GetPort: Integer;
begin
  Result := FdPort.Value;
end;

procedure TEspduTransformNode.SetPort(const Value: Integer);
begin
  FdPort.Send(Value);
end;

function TEspduTransformNode.GetReadInterval: TFloatTime;
begin
  Result := FdReadInterval.Value;
end;

procedure TEspduTransformNode.SetReadInterval(const Value: TFloatTime);
begin
  FdReadInterval.Send(Value);
end;

function TEspduTransformNode.GetRotation: TVector4Single;
begin
  Result := FdRotation.Value;
end;

procedure TEspduTransformNode.SetRotation(const Value: TVector4Single);
begin
  FdRotation.Send(Value);
end;

function TEspduTransformNode.GetScale: TVector3Single;
begin
  Result := FdScale.Value;
end;

procedure TEspduTransformNode.SetScale(const Value: TVector3Single);
begin
  FdScale.Send(Value);
end;

function TEspduTransformNode.GetScaleOrientation: TVector4Single;
begin
  Result := FdScaleOrientation.Value;
end;

procedure TEspduTransformNode.SetScaleOrientation(const Value: TVector4Single);
begin
  FdScaleOrientation.Send(Value);
end;

function TEspduTransformNode.GetSiteID: Integer;
begin
  Result := FdSiteID.Value;
end;

procedure TEspduTransformNode.SetSiteID(const Value: Integer);
begin
  FdSiteID.Send(Value);
end;

function TEspduTransformNode.GetTranslation: TVector3Single;
begin
  Result := FdTranslation.Value;
end;

procedure TEspduTransformNode.SetTranslation(const Value: TVector3Single);
begin
  FdTranslation.Send(Value);
end;

function TEspduTransformNode.GetWarhead: Integer;
begin
  Result := FdWarhead.Value;
end;

procedure TEspduTransformNode.SetWarhead(const Value: Integer);
begin
  FdWarhead.Send(Value);
end;

function TEspduTransformNode.GetWriteInterval: TFloatTime;
begin
  Result := FdWriteInterval.Value;
end;

procedure TEspduTransformNode.SetWriteInterval(const Value: TFloatTime);
begin
  FdWriteInterval.Send(Value);
end;

function TEspduTransformNode.GetRtpHeaderExpected: boolean;
begin
  Result := FdRtpHeaderExpected.Value;
end;

procedure TEspduTransformNode.SetRtpHeaderExpected(const Value: boolean);
begin
  FdRtpHeaderExpected.Send(Value);
end;

{$endif read_implementation}