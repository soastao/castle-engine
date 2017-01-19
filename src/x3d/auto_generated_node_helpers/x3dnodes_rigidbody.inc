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
    function GetAngularDampingFactor: Single;
    procedure SetAngularDampingFactor(const Value: Single);
    function GetAngularVelocity: TVector3Single;
    procedure SetAngularVelocity(const Value: TVector3Single);
    function GetAutoDamp: boolean;
    procedure SetAutoDamp(const Value: boolean);
    function GetAutoDisable: boolean;
    procedure SetAutoDisable(const Value: boolean);
    function GetCenterOfMass: TVector3Single;
    procedure SetCenterOfMass(const Value: TVector3Single);
    function GetDisableAngularSpeed: Single;
    procedure SetDisableAngularSpeed(const Value: Single);
    function GetDisableLinearSpeed: Single;
    procedure SetDisableLinearSpeed(const Value: Single);
    function GetDisableTime: Single;
    procedure SetDisableTime(const Value: Single);
    function GetEnabled: boolean;
    procedure SetEnabled(const Value: boolean);
    function GetFiniteRotationAxis: TVector3Single;
    procedure SetFiniteRotationAxis(const Value: TVector3Single);
    function GetFixed: boolean;
    procedure SetFixed(const Value: boolean);
    function GetInertia: TMatrix3Single;
    procedure SetInertia(const Value: TMatrix3Single);
    function GetLinearDampingFactor: Single;
    procedure SetLinearDampingFactor(const Value: Single);
    function GetLinearVelocity: TVector3Single;
    procedure SetLinearVelocity(const Value: TVector3Single);
    function GetMass: Single;
    procedure SetMass(const Value: Single);
    function GetOrientation: TVector4Single;
    procedure SetOrientation(const Value: TVector4Single);
    function GetPosition: TVector3Single;
    procedure SetPosition(const Value: TVector3Single);
    function GetUseFiniteRotation: boolean;
    procedure SetUseFiniteRotation(const Value: boolean);
    function GetUseGlobalGravity: boolean;
    procedure SetUseGlobalGravity(const Value: boolean);
  public
    property AngularDampingFactor: Single read GetAngularDampingFactor write SetAngularDampingFactor;
    property AngularVelocity: TVector3Single read GetAngularVelocity write SetAngularVelocity;
    property AutoDamp: boolean read GetAutoDamp write SetAutoDamp;
    property AutoDisable: boolean read GetAutoDisable write SetAutoDisable;
    property CenterOfMass: TVector3Single read GetCenterOfMass write SetCenterOfMass;
    property DisableAngularSpeed: Single read GetDisableAngularSpeed write SetDisableAngularSpeed;
    property DisableLinearSpeed: Single read GetDisableLinearSpeed write SetDisableLinearSpeed;
    property DisableTime: Single read GetDisableTime write SetDisableTime;
    property Enabled: boolean read GetEnabled write SetEnabled;
    property FiniteRotationAxis: TVector3Single read GetFiniteRotationAxis write SetFiniteRotationAxis;
    property Fixed: boolean read GetFixed write SetFixed;
    property Inertia: TMatrix3Single read GetInertia write SetInertia;
    property LinearDampingFactor: Single read GetLinearDampingFactor write SetLinearDampingFactor;
    property LinearVelocity: TVector3Single read GetLinearVelocity write SetLinearVelocity;
    property Mass: Single read GetMass write SetMass;
    property Orientation: TVector4Single read GetOrientation write SetOrientation;
    property Position: TVector3Single read GetPosition write SetPosition;
    property UseFiniteRotation: boolean read GetUseFiniteRotation write SetUseFiniteRotation;
    property UseGlobalGravity: boolean read GetUseGlobalGravity write SetUseGlobalGravity;

{$endif read_interface}

{$ifdef read_implementation}

{ TRigidBodyNode ----------------------------------------------- }

function TRigidBodyNode.GetAngularDampingFactor: Single;
begin
  Result := FdAngularDampingFactor.Value;
end;

procedure TRigidBodyNode.SetAngularDampingFactor(const Value: Single);
begin
  FdAngularDampingFactor.Send(Value);
end;

function TRigidBodyNode.GetAngularVelocity: TVector3Single;
begin
  Result := FdAngularVelocity.Value;
end;

procedure TRigidBodyNode.SetAngularVelocity(const Value: TVector3Single);
begin
  FdAngularVelocity.Send(Value);
end;

function TRigidBodyNode.GetAutoDamp: boolean;
begin
  Result := FdAutoDamp.Value;
end;

procedure TRigidBodyNode.SetAutoDamp(const Value: boolean);
begin
  FdAutoDamp.Send(Value);
end;

function TRigidBodyNode.GetAutoDisable: boolean;
begin
  Result := FdAutoDisable.Value;
end;

procedure TRigidBodyNode.SetAutoDisable(const Value: boolean);
begin
  FdAutoDisable.Send(Value);
end;

function TRigidBodyNode.GetCenterOfMass: TVector3Single;
begin
  Result := FdCenterOfMass.Value;
end;

procedure TRigidBodyNode.SetCenterOfMass(const Value: TVector3Single);
begin
  FdCenterOfMass.Send(Value);
end;

function TRigidBodyNode.GetDisableAngularSpeed: Single;
begin
  Result := FdDisableAngularSpeed.Value;
end;

procedure TRigidBodyNode.SetDisableAngularSpeed(const Value: Single);
begin
  FdDisableAngularSpeed.Send(Value);
end;

function TRigidBodyNode.GetDisableLinearSpeed: Single;
begin
  Result := FdDisableLinearSpeed.Value;
end;

procedure TRigidBodyNode.SetDisableLinearSpeed(const Value: Single);
begin
  FdDisableLinearSpeed.Send(Value);
end;

function TRigidBodyNode.GetDisableTime: Single;
begin
  Result := FdDisableTime.Value;
end;

procedure TRigidBodyNode.SetDisableTime(const Value: Single);
begin
  FdDisableTime.Send(Value);
end;

function TRigidBodyNode.GetEnabled: boolean;
begin
  Result := FdEnabled.Value;
end;

procedure TRigidBodyNode.SetEnabled(const Value: boolean);
begin
  FdEnabled.Send(Value);
end;

function TRigidBodyNode.GetFiniteRotationAxis: TVector3Single;
begin
  Result := FdFiniteRotationAxis.Value;
end;

procedure TRigidBodyNode.SetFiniteRotationAxis(const Value: TVector3Single);
begin
  FdFiniteRotationAxis.Send(Value);
end;

function TRigidBodyNode.GetFixed: boolean;
begin
  Result := FdFixed.Value;
end;

procedure TRigidBodyNode.SetFixed(const Value: boolean);
begin
  FdFixed.Send(Value);
end;

function TRigidBodyNode.GetInertia: TMatrix3Single;
begin
  Result := FdInertia.Value;
end;

procedure TRigidBodyNode.SetInertia(const Value: TMatrix3Single);
begin
  FdInertia.Send(Value);
end;

function TRigidBodyNode.GetLinearDampingFactor: Single;
begin
  Result := FdLinearDampingFactor.Value;
end;

procedure TRigidBodyNode.SetLinearDampingFactor(const Value: Single);
begin
  FdLinearDampingFactor.Send(Value);
end;

function TRigidBodyNode.GetLinearVelocity: TVector3Single;
begin
  Result := FdLinearVelocity.Value;
end;

procedure TRigidBodyNode.SetLinearVelocity(const Value: TVector3Single);
begin
  FdLinearVelocity.Send(Value);
end;

function TRigidBodyNode.GetMass: Single;
begin
  Result := FdMass.Value;
end;

procedure TRigidBodyNode.SetMass(const Value: Single);
begin
  FdMass.Send(Value);
end;

function TRigidBodyNode.GetOrientation: TVector4Single;
begin
  Result := FdOrientation.Value;
end;

procedure TRigidBodyNode.SetOrientation(const Value: TVector4Single);
begin
  FdOrientation.Send(Value);
end;

function TRigidBodyNode.GetPosition: TVector3Single;
begin
  Result := FdPosition.Value;
end;

procedure TRigidBodyNode.SetPosition(const Value: TVector3Single);
begin
  FdPosition.Send(Value);
end;

function TRigidBodyNode.GetUseFiniteRotation: boolean;
begin
  Result := FdUseFiniteRotation.Value;
end;

procedure TRigidBodyNode.SetUseFiniteRotation(const Value: boolean);
begin
  FdUseFiniteRotation.Send(Value);
end;

function TRigidBodyNode.GetUseGlobalGravity: boolean;
begin
  Result := FdUseGlobalGravity.Value;
end;

procedure TRigidBodyNode.SetUseGlobalGravity(const Value: boolean);
begin
  FdUseGlobalGravity.Send(Value);
end;

{$endif read_implementation}