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
    function GetAutoDisable: boolean;
    procedure SetAutoDisable(const Value: boolean);
    function GetConstantForceMix: Single;
    procedure SetConstantForceMix(const Value: Single);
    function GetContactSurfaceThickness: Single;
    procedure SetContactSurfaceThickness(const Value: Single);
    function GetDisableAngularSpeed: Single;
    procedure SetDisableAngularSpeed(const Value: Single);
    function GetDisableLinearSpeed: Single;
    procedure SetDisableLinearSpeed(const Value: Single);
    function GetDisableTime: Single;
    procedure SetDisableTime(const Value: Single);
    function GetEnabled: boolean;
    procedure SetEnabled(const Value: boolean);
    function GetErrorCorrection: Single;
    procedure SetErrorCorrection(const Value: Single);
    function GetGravity: TVector3Single;
    procedure SetGravity(const Value: TVector3Single);
    function GetIterations: Integer;
    procedure SetIterations(const Value: Integer);
    function GetMaxCorrectionSpeed: Single;
    procedure SetMaxCorrectionSpeed(const Value: Single);
    function GetPreferAccuracy: boolean;
    procedure SetPreferAccuracy(const Value: boolean);
  public
    property AutoDisable: boolean read GetAutoDisable write SetAutoDisable;
    property ConstantForceMix: Single read GetConstantForceMix write SetConstantForceMix;
    property ContactSurfaceThickness: Single read GetContactSurfaceThickness write SetContactSurfaceThickness;
    property DisableAngularSpeed: Single read GetDisableAngularSpeed write SetDisableAngularSpeed;
    property DisableLinearSpeed: Single read GetDisableLinearSpeed write SetDisableLinearSpeed;
    property DisableTime: Single read GetDisableTime write SetDisableTime;
    property Enabled: boolean read GetEnabled write SetEnabled;
    property ErrorCorrection: Single read GetErrorCorrection write SetErrorCorrection;
    property Gravity: TVector3Single read GetGravity write SetGravity;
    property Iterations: Integer read GetIterations write SetIterations;
    property MaxCorrectionSpeed: Single read GetMaxCorrectionSpeed write SetMaxCorrectionSpeed;
    property PreferAccuracy: boolean read GetPreferAccuracy write SetPreferAccuracy;

{$endif read_interface}

{$ifdef read_implementation}

{ TRigidBodyCollectionNode ----------------------------------------------- }

function TRigidBodyCollectionNode.GetAutoDisable: boolean;
begin
  Result := FdAutoDisable.Value;
end;

procedure TRigidBodyCollectionNode.SetAutoDisable(const Value: boolean);
begin
  FdAutoDisable.Send(Value);
end;

function TRigidBodyCollectionNode.GetConstantForceMix: Single;
begin
  Result := FdConstantForceMix.Value;
end;

procedure TRigidBodyCollectionNode.SetConstantForceMix(const Value: Single);
begin
  FdConstantForceMix.Send(Value);
end;

function TRigidBodyCollectionNode.GetContactSurfaceThickness: Single;
begin
  Result := FdContactSurfaceThickness.Value;
end;

procedure TRigidBodyCollectionNode.SetContactSurfaceThickness(const Value: Single);
begin
  FdContactSurfaceThickness.Send(Value);
end;

function TRigidBodyCollectionNode.GetDisableAngularSpeed: Single;
begin
  Result := FdDisableAngularSpeed.Value;
end;

procedure TRigidBodyCollectionNode.SetDisableAngularSpeed(const Value: Single);
begin
  FdDisableAngularSpeed.Send(Value);
end;

function TRigidBodyCollectionNode.GetDisableLinearSpeed: Single;
begin
  Result := FdDisableLinearSpeed.Value;
end;

procedure TRigidBodyCollectionNode.SetDisableLinearSpeed(const Value: Single);
begin
  FdDisableLinearSpeed.Send(Value);
end;

function TRigidBodyCollectionNode.GetDisableTime: Single;
begin
  Result := FdDisableTime.Value;
end;

procedure TRigidBodyCollectionNode.SetDisableTime(const Value: Single);
begin
  FdDisableTime.Send(Value);
end;

function TRigidBodyCollectionNode.GetEnabled: boolean;
begin
  Result := FdEnabled.Value;
end;

procedure TRigidBodyCollectionNode.SetEnabled(const Value: boolean);
begin
  FdEnabled.Send(Value);
end;

function TRigidBodyCollectionNode.GetErrorCorrection: Single;
begin
  Result := FdErrorCorrection.Value;
end;

procedure TRigidBodyCollectionNode.SetErrorCorrection(const Value: Single);
begin
  FdErrorCorrection.Send(Value);
end;

function TRigidBodyCollectionNode.GetGravity: TVector3Single;
begin
  Result := FdGravity.Value;
end;

procedure TRigidBodyCollectionNode.SetGravity(const Value: TVector3Single);
begin
  FdGravity.Send(Value);
end;

function TRigidBodyCollectionNode.GetIterations: Integer;
begin
  Result := FdIterations.Value;
end;

procedure TRigidBodyCollectionNode.SetIterations(const Value: Integer);
begin
  FdIterations.Send(Value);
end;

function TRigidBodyCollectionNode.GetMaxCorrectionSpeed: Single;
begin
  Result := FdMaxCorrectionSpeed.Value;
end;

procedure TRigidBodyCollectionNode.SetMaxCorrectionSpeed(const Value: Single);
begin
  FdMaxCorrectionSpeed.Send(Value);
end;

function TRigidBodyCollectionNode.GetPreferAccuracy: boolean;
begin
  Result := FdPreferAccuracy.Value;
end;

procedure TRigidBodyCollectionNode.SetPreferAccuracy(const Value: boolean);
begin
  FdPreferAccuracy.Send(Value);
end;

{$endif read_implementation}