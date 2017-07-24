{
  Copyright 2008-2017 Michalis Kamburelis.

  This file is part of "Castle Game Engine".

  "Castle Game Engine" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Castle Game Engine" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ CastleScript array types and built-in functions. }
unit CastleScriptArrays;

{$I castleconf.inc}

interface

uses CastleVectors, CastleScript, CastleScriptVectors, CastleUtils, CastleStringUtils,
  CastleScriptCoreFunctions, CastleInternalDoubleLists;

type
  TCasScriptArrayFun = class;
  TCasScriptArrayD = class;

  generic TCasScriptArray<
    TXxxList,
    TCasScriptXxxElement,
    TCasScriptXxxArrayFun> = class(TCasScriptValue)
  private
    FValue: TXxxList;
    class procedure HandleArrayFun(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: boolean);
    class procedure HandleArrayGetCount(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: boolean);
    class procedure HandleArraySetCount(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: boolean);
    class procedure HandleArrayGet(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: boolean);
    class procedure HandleArraySet(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: boolean);
    class procedure HandleAdd(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: boolean);
    procedure SetValue(const AValue: TXxxList);
    class procedure RegisterFunctions;
  public
    constructor Create(const AWriteable: boolean; const AValue: TXxxList);
    constructor Create(const AWriteable: boolean); override;
    destructor Destroy; override;

    { Array value. Assigning here makes a @italic(copy) of the array. }
    property Value: TXxxList read FValue write SetValue;

    procedure AssignValue(Source: TCasScriptValue); override;
  end;

  TCasScriptLongIntArray = class(specialize TCasScriptArray<
    TLongIntList,
    TCasScriptInteger,
    TCasScriptArrayFun>)
  end;

  TCasScriptSingleArray = class(specialize TCasScriptArray<
    TSingleList,
    TCasScriptFloat,
    TCasScriptArrayFun>)
  private
    class procedure HandleCatmullRomSpline(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: boolean);
    class procedure HandleHermiteSpline(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: boolean);
    class procedure HandleHermiteTenseSpline(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: boolean);
  end;

  TCasScriptDoubleArray = class(specialize TCasScriptArray<
    TDoubleList,
    TCasScriptFloat,
    TCasScriptArrayD>)
  end;

  TCasScriptBooleanArray = class(specialize TCasScriptArray<
    TBooleanList,
    TCasScriptBoolean,
    TCasScriptArrayFun>)
  end;

  TCasScriptStringArray = class(specialize TCasScriptArray<
    TCastleStringList,
    TCasScriptString,
    TCasScriptArrayFun>)
  end;

  TCasScriptVec2fArray = class(specialize TCasScriptArray<
    TVector2List,
    TCasScriptVec2f,
    TCasScriptArrayFun>)
  end;

  TCasScriptVec3fArray = class(specialize TCasScriptArray<
    TVector3List,
    TCasScriptVec3f,
    TCasScriptArrayFun>)
  end;

  TCasScriptVec4fArray = class(specialize TCasScriptArray<
    TVector4List,
    TCasScriptVec4f,
    TCasScriptArrayFun>)
  end;

  TCasScriptVec2dArray = class(specialize TCasScriptArray<
    TVector2DoubleList,
    TCasScriptVec2d,
    TCasScriptArrayFun>)
  end;

  TCasScriptVec3dArray = class(specialize TCasScriptArray<
    TVector3DoubleList,
    TCasScriptVec3d,
    TCasScriptArrayFun>)
  end;

  TCasScriptVec4dArray = class(specialize TCasScriptArray<
    TVector4DoubleList,
    TCasScriptVec4d,
    TCasScriptArrayFun>)
  end;

  TCasScriptMatrix3DoubleArray = class(specialize TCasScriptArray<
    TMatrix3DoubleList,
    TCasScriptMatrix3Double,
    TCasScriptArrayFun>)
  end;

  TCasScriptMatrix4DoubleArray = class(specialize TCasScriptArray<
    TMatrix4DoubleList,
    TCasScriptMatrix4Double,
    TCasScriptArrayFun>)
  end;

  TCasScriptMatrix3fArray = class(specialize TCasScriptArray<
    TMatrix3List,
    TCasScriptMatrix3f,
    TCasScriptArrayFun>)
  end;

  TCasScriptMatrix4fArray = class(specialize TCasScriptArray<
    TMatrix4List,
    TCasScriptMatrix4f,
    TCasScriptArrayFun>)
  end;

  TCasScriptArrayFun = class(TCasScriptFunction)
  public
    class function ShortName: string; override;
  end;

  TCasScriptArrayD = class(TCasScriptFunction)
  public
    class function ShortName: string; override;
  end;

  TCasScriptArrayGetCount = class(TCasScriptFunction)
  public
    class function ShortName: string; override;
  end;

  TCasScriptArraySetCount = class(TCasScriptFunction)
  public
    class function ShortName: string; override;
    class function ArgumentMustBeAssignable(const Index: Integer): boolean; override;
  end;

  TCasScriptArrayGet = class(TCasScriptFunction)
  public
    class function ShortName: string; override;
  end;

  TCasScriptArraySet = class(TCasScriptFunction)
  public
    class function ShortName: string; override;
    class function ArgumentMustBeAssignable(const Index: Integer): boolean; override;
  end;

  TCasScriptCatmullRomSpline = class(TCasScriptFunction)
  public
    class function ShortName: string; override;
  end;

  TCasScriptHermiteSpline = class(TCasScriptFunction)
  public
    class function ShortName: string; override;
  end;

  TCasScriptHermiteTenseSpline = class(TCasScriptFunction)
  public
    class function ShortName: string; override;
  end;

implementation

uses SysUtils, CastleCurves;

{ TCasScriptArray ------------------------------------------------------------ }

constructor TCasScriptArray.Create(const AWriteable: boolean; const AValue: TXxxList);
begin
  Create(AWriteable);
  Value := AValue;
end;

constructor TCasScriptArray.Create(const AWriteable: boolean);
begin
  inherited;
  FValue := TXxxList.Create;
end;

destructor TCasScriptArray.Destroy;
begin
  FreeAndNil(FValue);
  inherited;
end;

procedure TCasScriptArray.SetValue(const AValue: TXxxList);
begin
  FValue.Assign(AValue);
  ValueAssigned := true;
end;

procedure TCasScriptArray.AssignValue(Source: TCasScriptValue);
begin
  { This works just as well:

      if Source.InheritsFrom(ClassType) then

    Note that it requires that we create

      CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptValueClass(ClassType));

    and *not*

      CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptArray);

    since the actual class type (like TCasScriptStringArray) is a descendant
    of TCasScriptArray specialization like
    TCasScriptArray<CastleStringUtils.TCastleStringList,CastleScript.TCasScriptString,CastleScriptArrays.TCasScriptArrayFun>
  }

  if Source is TCasScriptArray then
    Value := TCasScriptArray(Source).Value
  else
    raise ECasScriptAssignError.CreateFmt('Assignment from %s to %s not possible', [Source.ClassName, ClassName]);
end;

class procedure TCasScriptArray.HandleArrayFun(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: boolean);
var
  I: Integer;
  Arr: TXxxList;
begin
  { Make AResult an instance of the self class, like TCasScriptLongIntArray
    when this generic is specialized to TCasScriptLongIntArray. }
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptValueClass(ClassType));

  Arr := TCasScriptArray(AResult).Value;
  Arr.Count := Length(Arguments);
  for I := 0 to Length(Arguments) - 1 do
    Arr.L[I] := TCasScriptXxxElement(Arguments[I]).Value;

  AResult.ValueAssigned := true;
end;

class procedure TCasScriptArray.HandleArrayGetCount(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptInteger);
  TCasScriptInteger(AResult).Value := TCasScriptArray(Arguments[0]).Value.Count;
end;

class procedure TCasScriptArray.HandleArraySetCount(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: boolean);
var
  NewCount: Int64;
begin
  if ParentOfResult then
    AResult.FreeByParentExpression;
  AResult := nil;
  ParentOfResult := false;

  NewCount := TCasScriptInteger(Arguments[1]).Value;
  if NewCount < 0 then
    raise ECasScriptError.CreateFmt('Invalid count %d for array_set_count (should be non-negative)',
      [NewCount]);

  TCasScriptArray(Arguments[0]).Value.Count := NewCount;
  Arguments[0].ValueAssigned := true;

  AResult := Arguments[0];
end;

class procedure TCasScriptArray.HandleArrayGet(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: boolean);
var
  Index: Integer;
  Arr: TXxxList;
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptXxxElement);

  Arr := TCasScriptArray(Arguments[0]).Value;

  Index := TCasScriptInteger(Arguments[1]).Value;
  if not Between(Index, 0, Arr.Count - 1) then
    raise ECasScriptError.CreateFmt('Invalid index %d for array_get, array count is %d',
      [Index, Arr.Count]);

  TCasScriptXxxElement(AResult).Value := Arr.L[Index];
end;

class procedure TCasScriptArray.HandleArraySet(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: boolean);
var
  Index: Integer;
  Arr: TXxxList;
begin
  if ParentOfResult then
    AResult.FreeByParentExpression;
  AResult := nil;
  ParentOfResult := false;

  Arr := TCasScriptArray(Arguments[0]).Value;

  Index := TCasScriptInteger(Arguments[1]).Value;
  if not Between(Index, 0, Arr.Count - 1) then
    raise ECasScriptError.CreateFmt('Invalid index %d for array_set, array count is %d',
      [Index, Arr.Count]);

  Arr.L[Index] := TCasScriptXxxElement(Arguments[2]).Value;
  Arguments[0].ValueAssigned := true;

  AResult := Arguments[0];
end;

class procedure TCasScriptArray.HandleAdd(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: boolean);
var
  I: Integer;
  Arr: TXxxList;
begin
  { Make AResult an instance of the self class, like TCasScriptLongIntArray
    when this generic is specialized to TCasScriptLongIntArray. }
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptValueClass(ClassType));

  Arr := TCasScriptArray(AResult).Value;
  { initially Arr is empty. This is needed to set explicitly,
    since CreateValueIfNeeded could left previous AResult }
  Arr.Clear;
  for I := 0 to Length(Arguments) - 1 do
    Arr.AddRange(TCasScriptArray(Arguments[I]).Value);

  AResult.ValueAssigned := true;
end;

class procedure TCasScriptArray.RegisterFunctions;
begin
  FunctionHandlers.RegisterHandler(@HandleArrayFun, TCasScriptXxxArrayFun, [TCasScriptXxxElement], true);
  FunctionHandlers.RegisterHandler(@HandleArrayGetCount, TCasScriptArrayGetCount, [TCasScriptArray], false);
  FunctionHandlers.RegisterHandler(@HandleArraySetCount, TCasScriptArraySetCount, [TCasScriptArray, TCasScriptInteger], false);
  FunctionHandlers.RegisterHandler(@HandleArrayGet, TCasScriptArrayGet, [TCasScriptArray, TCasScriptInteger], false);
  FunctionHandlers.RegisterHandler(@HandleArraySet, TCasScriptArraySet, [TCasScriptArray, TCasScriptInteger, TCasScriptXxxElement], false);
  FunctionHandlers.RegisterHandler(@HandleAdd, TCasScriptAdd, [TCasScriptArray], true);
end;

{ TCasScriptSingleArray specials --------------------------------------------- }

class procedure TCasScriptSingleArray.HandleCatmullRomSpline(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value := CatmullRomSpline(
    TCasScriptFloat(Arguments[0]).Value,
    TCasScriptBoolean(Arguments[1]).Value,
    TCasScriptSingleArray(Arguments[2]).Value,
    TCasScriptSingleArray(Arguments[3]).Value);
end;

class procedure TCasScriptSingleArray.HandleHermiteSpline(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value := HermiteSpline(
    TCasScriptFloat(Arguments[0]).Value,
    TCasScriptBoolean(Arguments[1]).Value,
    TCasScriptSingleArray(Arguments[2]).Value,
    TCasScriptSingleArray(Arguments[3]).Value,
    TCasScriptSingleArray(Arguments[4]).Value);
end;

class procedure TCasScriptSingleArray.HandleHermiteTenseSpline(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value := HermiteTenseSpline(
    TCasScriptFloat(Arguments[0]).Value,
    TCasScriptBoolean(Arguments[1]).Value,
    TCasScriptSingleArray(Arguments[2]).Value,
    TCasScriptSingleArray(Arguments[3]).Value);
end;

{ CastleScript functions ------------------------------------------------------ }

class function TCasScriptArrayFun.ShortName: string;
begin
  Result := 'array';
end;

class function TCasScriptArrayD.ShortName: string;
begin
  Result := 'array_d';
end;

class function TCasScriptArrayGetCount.ShortName: string;
begin
  Result := 'array_get_count';
end;

class function TCasScriptArraySetCount.ShortName: string;
begin
  Result := 'array_set_count';
end;

class function TCasScriptArraySetCount.ArgumentMustBeAssignable(const Index: Integer): boolean;
begin
  Result := Index = 0;
end;

class function TCasScriptArrayGet.ShortName: string;
begin
  Result := 'array_get';
end;

class function TCasScriptArraySet.ShortName: string;
begin
  Result := 'array_set';
end;

class function TCasScriptArraySet.ArgumentMustBeAssignable(const Index: Integer): boolean;
begin
  Result := Index = 0;
end;

class function TCasScriptCatmullRomSpline.ShortName: string;
begin
  Result := 'catmull_rom_spline';
end;

class function TCasScriptHermiteSpline.ShortName: string;
begin
  Result := 'hermite_spline';
end;

class function TCasScriptHermiteTenseSpline.ShortName: string;
begin
  Result := 'hermite_tense_spline';
end;

{ Handling strings as arrays of characters ----------------------------------- }

type
  TCasScriptCharacterArray = class
    class procedure HandleArrayGetCount(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: boolean);
    class procedure HandleArraySetCount(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: boolean);
    class procedure HandleArrayGet(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: boolean);
    class procedure HandleArraySet(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: boolean);
  end;

class procedure TCasScriptCharacterArray.HandleArrayGetCount(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptInteger);
  TCasScriptInteger(AResult).Value := Length(TCasScriptString(Arguments[0]).Value);
end;

class procedure TCasScriptCharacterArray.HandleArraySetCount(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: boolean);
var
  NewCount: Int64;
  NewValue: string;
begin
  if ParentOfResult then
    AResult.FreeByParentExpression;
  AResult := nil;
  ParentOfResult := false;

  NewCount := TCasScriptInteger(Arguments[1]).Value;
  if NewCount < 0 then
    raise ECasScriptError.CreateFmt('Invalid count %d for array_set_count (should be non-negative)',
      [NewCount]);

  NewValue := TCasScriptString(Arguments[0]).Value;
  SetLength(NewValue, NewCount);
  TCasScriptString(Arguments[0]).Value := NewValue;

  TCasScriptString(Arguments[0]).ValueAssigned := true;

  AResult := Arguments[0];
end;

class procedure TCasScriptCharacterArray.HandleArrayGet(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: boolean);
var
  Index: Integer;
  Arr: string;
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptString);

  Arr := TCasScriptString(Arguments[0]).Value;

  Index := TCasScriptInteger(Arguments[1]).Value;
  if not Between(Index, 0, Length(Arr) - 1) then
    raise ECasScriptError.CreateFmt('Invalid index %d for array_get, array count is %d',
      [Index, Length(Arr)]);

  TCasScriptString(AResult).Value := Arr[Index+1];
end;

class procedure TCasScriptCharacterArray.HandleArraySet(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: boolean);
var
  Index: Integer;
  Arr: string;
begin
  if ParentOfResult then
    AResult.FreeByParentExpression;
  AResult := nil;
  ParentOfResult := false;

  Arr := TCasScriptString(Arguments[0]).Value;

  Index := TCasScriptInteger(Arguments[1]).Value;
  if not Between(Index, 0, Length(Arr) - 1) then
    raise ECasScriptError.CreateFmt('Invalid index %d for array_set, array count is %d',
      [Index, Length(Arr)]);

  if Length(TCasScriptString(Arguments[2]).Value) <> 1 then
    raise ECasScriptError.CreateFmt('Invalid value as the last array_set argument: given array is a string, so value is expected to be a character (that is, a string of length exactly 1). But given value is "%s" (length %d)',
      [ TCasScriptString(Arguments[2]).Value,
        Length(TCasScriptString(Arguments[2]).Value) ]);

  Arr[Index+1] := TCasScriptString(Arguments[2]).Value[1];
  TCasScriptString(Arguments[0]).Value := Arr;

  AResult := Arguments[0];
end;

procedure RegisterCharacterFunctions;
begin
  FunctionHandlers.RegisterHandler(@TCasScriptCharacterArray(nil).HandleArrayGetCount, TCasScriptArrayGetCount, [TCasScriptString], false);
  FunctionHandlers.RegisterHandler(@TCasScriptCharacterArray(nil).HandleArraySetCount, TCasScriptArraySetCount, [TCasScriptString, TCasScriptInteger], false);
  FunctionHandlers.RegisterHandler(@TCasScriptCharacterArray(nil).HandleArrayGet, TCasScriptArrayGet, [TCasScriptString, TCasScriptInteger], false);
  FunctionHandlers.RegisterHandler(@TCasScriptCharacterArray(nil).HandleArraySet, TCasScriptArraySet, [TCasScriptString, TCasScriptInteger, TCasScriptString], false);
end;

initialization
  TCasScriptLongIntArray.RegisterFunctions;
  TCasScriptSingleArray.RegisterFunctions;
  TCasScriptDoubleArray.RegisterFunctions;
  TCasScriptBooleanArray.RegisterFunctions;
  TCasScriptStringArray.RegisterFunctions;

  TCasScriptVec2fArray.RegisterFunctions;
  TCasScriptVec3fArray.RegisterFunctions;
  TCasScriptVec4fArray.RegisterFunctions;
  TCasScriptMatrix3fArray.RegisterFunctions;
  TCasScriptMatrix4fArray.RegisterFunctions;

  TCasScriptVec2dArray.RegisterFunctions;
  TCasScriptVec3dArray.RegisterFunctions;
  TCasScriptVec4dArray.RegisterFunctions;
  TCasScriptMatrix3DoubleArray.RegisterFunctions;
  TCasScriptMatrix4DoubleArray.RegisterFunctions;

  FunctionHandlers.RegisterHandler(@TCasScriptSingleArray(nil).HandleCatmullRomSpline, TCasScriptCatmullRomSpline, [TCasScriptFloat, TCasScriptBoolean, TCasScriptSingleArray, TCasScriptSingleArray], false);
  FunctionHandlers.RegisterHandler(@TCasScriptSingleArray(nil).HandleHermiteSpline, TCasScriptHermiteSpline, [TCasScriptFloat, TCasScriptBoolean, TCasScriptSingleArray, TCasScriptSingleArray, TCasScriptSingleArray], false);
  FunctionHandlers.RegisterHandler(@TCasScriptSingleArray(nil).HandleHermiteTenseSpline, TCasScriptHermiteTenseSpline, [TCasScriptFloat, TCasScriptBoolean, TCasScriptSingleArray, TCasScriptSingleArray], false);

  RegisterCharacterFunctions;
end.
