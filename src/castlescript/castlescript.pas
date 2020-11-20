{
  Copyright 2001-2018 Michalis Kamburelis.

  This file is part of "Castle Game Engine".

  "Castle Game Engine" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Castle Game Engine" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Base CastleScript structures: values, functions, expressions.

  It is designed to be extendable, so you can add new TCasScriptValue
  descendants and new TCasScriptFunction descendants, and register
  their handlers in FunctionHandlers instance (TCasScriptFunctionHandlers).

  Using structures here you can also build CastleScript expressions
  by Pascal code (that is, you don't have to parse them). For example
  this is an expression that calculates @code(sin(3) + 10 + 1):

  @longcode(#
    Expr := TCasScriptAdd.Create([
        TCasScriptSin.Create([TCasScriptFloat.Create(false, 3)]),
        TCasScriptFloat.Create(false, 10),
        TCasScriptFloat.Create(false, 1)
      ]);
  #)

  You can then call @code(Expr.Execute) to calculate such expression.

  To make a variable in the expression, just create and remember a
  TCasScriptFloat instance first, and then change it's value freely between
  @code(Expr.Execute) calls. For example

  @longcode(#
    MyVariable := TCasScriptFloat.Create(false, 3);
    Expr := TCasScriptAdd.Create([
        TCasScriptSin.Create([MyVariable]),
        TCasScriptFloat.Create(false, 10),
        TCasScriptFloat.Create(false, 1)
      ]);

    Writeln((Expr.Execute as TKamStringFloat).Value); // calculate "sin(3) + 10 + 1"

    MyVariable.Value := 4;
    Writeln((Expr.Execute as TKamStringFloat).Value); // calculate "sin(4) + 10 + 1"

    MyVariable.Value := 5;
    Writeln((Expr.Execute as TKamStringFloat).Value); // calculate "sin(5) + 10 + 1"
  #)

  Note that generally each TCasScriptExpression owns it's children
  expressions, so they will be automatically freed when parent is freed.
  Also, the values returned by Execute are owned by expression.
  So you can simply free whole thing by @code(Expr.Free).

  If you're want to parse CastleScript expression from a text
  file, see CastleScriptParser.
}
unit CastleScript;

{$I castleconf.inc}

interface

uses SysUtils, Math, Contnrs, Classes, Generics.Collections,
  CastleUtils, CastleClassUtils;

type
  { }
  TCasScriptValue = class;

  ECasScriptError = class(Exception);
  ECasScriptAssignError = class(ECasScriptError);
  ECasScriptAnyMathError = class(ECasScriptError);

  { @deprecated Deprecated name for ECasScriptAssignError. }
  EKamAssignValueError = ECasScriptAssignError deprecated;

  TCasScriptMessage = procedure (const S: String) of object;

  { Various information that may be useful for implementing some
    function handlers, but that should be supplied from outside of
    CastleScript. }
  TCasScriptEnvironment = class
  private
    FBaseUrl: String;
  public
    { Base URL to resolve relative URLs. Similar to TX3DNode.BaseUrl. }
    property BaseUrl: String read FBaseUrl write FBaseUrl;
  end;

  TCasScriptExpression = class
  private
    FEnvironment: TCasScriptEnvironment;
  protected
    { More internal version of Execute.

      This doesn't necessarily check floating-point exceptions.
      Execute actually calls CoreExecute and then ClearExceptions.

      Also this doesn't try to convert EIntError and EMathError
      to ECasScriptAnyMathError. This is done by Execute.

      When one CastleScript CoreExecute calls another function,
      it can use CoreExecute instead of Execute. This way only one
      ClearExceptions will be needed for whole expression execution,
      instead of doing ClearExceptions after each function handler. }
    function CoreExecute: TCasScriptValue; virtual; abstract;
  public
    (*Execute and calculate this expression.

      Returned value is owned by this object. Which should be comfortable
      for you usually, as you do not have to worry about freeing it.
      Also, it allows us to make various optimizations to avoid
      creating/destroying lots of temporary TCasScriptExpression
      instances during calculation of complex expression.

      The disadvantage of this is that returned object value is valid
      only until you executed this same expression again,
      or until you freed this expression. If you need to remember the
      execute result for longer, you have to copy it somewhere.
      For example you can do

      @longCode(#
        { This will always work, thanks to virtual TCasScriptValue.Create
          and AssignValue methods. }
        Copy := TCasScriptValue(ReturnedValue.ClassType).Create;
        Copy.AssignValue(ReturnedValue);
      #)

      @raises(ECasScriptError

        Execute is guaranteed to raise an ECasScriptError exception if some
        calculation fails because of invalid arguments.

        This means that when you run CastleScript expression provided
        by the user, you only have to catch ECasScriptError
        to be safe from errors produced by user.
        No need to catch something more general like Exception class.

        Also it's guaranteed that no hanging floating-point errors
        are left. Normally, there is no guarantee that
        floating-point errors are raised immediately, they may
        be raised at the next fp operation (this is needed for fp operations
        to proceed in parallel, and be much faster).
        For executing CastleScript, Execute calls Math.ClearExceptions(true)
        to make sure that all floating point errors are caught.
        This ensures that we can safely execute even invalid expressions
        (like 'ln(-3)') and get reliable exceptions.

        Floating-point errors of course also result in ECasScriptError descendants.
        More specifically, EIntError and EMathError result
        in ECasScriptAnyMathError.)
    *)
    function Execute: TCasScriptValue;

    { Try to execute expression, or return @nil if a mathematical error occurred
      within expression. "Math error within expression" means that
      a ECasScriptAnyMathError exception occurred while calculating expression.

      This is useful to secure you against math arguments errors ('ln(-3)',
      'sqrt(-3)') but still raises normal exception on other ECasScriptError
      errors (like invalid argument type for function). }
    function TryExecuteMath: TCasScriptValue;

    { Execute expression, return the result as a simple float value.
      It assumes that the expression is written to always return float.
      To easily create such expression, use @link(ParseFloatExpression). }
    function AsFloat(const ADefaultValue: Float = 0): Float;

    { Execute expression, return the result as a simple integer value.
      It assumes that the expression is written to always return integer.
      To easily create such expression, use @link(ParseIntExpression). }
    function AsInt(const ADefaultValue: Int64 = 0): Int64;

    { Execute expression, return the result as a simple String value.
      It assumes that the expression is written to always return String.
      To easily create such expression, use @link(ParseStringExpression). }
    function AsString(const ADefaultValue: String = ''): String;

    { Execute expression, return the result as a simple boolean value.
      It assumes that the expression is written to always return Boolean.
      To easily create such expression, use @link(ParseBoolExpression). }
    function AsBool(const ADefaultValue: Boolean = false): Boolean;

    { Call Free, but only if this is not TCasScriptValue with
      OwnedByParentExpression = false. (This cannot be implemented
      cleanly, as virtual procedure, since it must work when Self is @nil,
      and then virtual method table is not available of course.) }
    procedure FreeByParentExpression;

    { Environment (outside information) for this expression.
      May be @nil. This object is not owned by TCasScriptExpression,
      will not be freed by TCasScriptExpression and such. }
    property Environment: TCasScriptEnvironment read FEnvironment write FEnvironment;
  end;

  TCasScriptExpressionList = class({$ifdef CASTLE_OBJFPC}specialize{$endif} TObjectList<TCasScriptExpression>)
  public
    procedure AddArray(const A: array of TCasScriptExpression); deprecated 'use AddRange';
    procedure AddList(const Source: TCasScriptExpressionList); deprecated 'use AddRange';
    procedure FreeContentsByParentExpression;
  end;

  TCasScriptValue = class(TCasScriptExpression)
  private
    FOwnedByParentExpression: Boolean;
    FName: String;
    FValueAssigned: Boolean;
    FWriteable: Boolean;
  protected
    function CoreExecute: TCasScriptValue; override;
  public
    { Internal note: don't make this constructor overloaded with Delphi
      "overload" keyword, descendants depend that this class hides
      the parameter-less constructor of ancestors. }
    { }
    constructor Create(const AWriteable: Boolean); virtual;

    { Is this value writeable.
      If not, this will not be allowed to change by CastleScript assignment
      and such functions. Note that Writeable = @false will not prevent
      you from changing value internally, by AssignValue or changin
      Value property directly (that would be too uncomfortable). }
    property Writeable: Boolean read FWriteable write FWriteable;

    property OwnedByParentExpression: Boolean
      read FOwnedByParentExpression write FOwnedByParentExpression
      default true;

    { Name of this value, or '' if not named.
      Named value can be recognized in expressions by CastleScriptParser. }
    property Name: String read FName write FName;

    { Assign value from Source to Self.
      @raises(ECasScriptAssignError if assignment is not possible
      because types don't match.) }
    procedure AssignValue(Source: TCasScriptValue); virtual; abstract;

    { Set to @true on each assign to Value. You can reset it at any time
      to @false.

      This allows the caller to know which variables were
      assigned during script execution, which is useful if changes to
      CastleScript variables should be propagated to some other things
      after the script finished execution. This is essential for behavior
      in VRML/X3D Script node.

      Descendants note: you have to set this to @true in SetValue. }
    property ValueAssigned: Boolean read FValueAssigned write FValueAssigned
      default false;
  end;

  TCasScriptValueClass = class of TCasScriptValue;
  TCasScriptValueClassArray = array of TCasScriptValueClass;
  TCasScriptValuesArray = array of TCasScriptValue;

  TCasScriptValueList = class({$ifdef CASTLE_OBJFPC}specialize{$endif} TObjectList<TCasScriptValue>)
  public
    procedure AddArray(const A: array of TCasScriptValue); deprecated 'use AddRange';
    { Find an item by Name. @nil if not found. }
    function FindName(const VariableName: String): TCasScriptValue;
  end;

  { This is a very special CastleScript value, used to represent user-defined
    function parameter. This poses itself as a TCasScriptValue descendant,
    and it has working AssignValue and everything else. This way it can
    be used in "Variables" list for various CastleScriptParser functions.

    Except it's cheating: it doesn't actually store the value.
    Instead, it has SourceValue property that is used when doing
    AssignValue. So AssignValue is handled by SourceValue.AssignValue,
    and Execute is handled by SourceValue.Execute, and so reading/writing
    this works.

    The advantage: the exact type of function parameter is not known,
    and still we can parse the function expression. This is crucial
    for parser implementation: when parsing you need to create
    TCasScriptParameterValue instance, but you don't know actual
    type of parameter that will be passed here. }
  TCasScriptParameterValue = class(TCasScriptValue)
  private
    FSourceValue: TCasScriptValue;
  protected
    function CoreExecute: TCasScriptValue; override;
  public
    property SourceValue: TCasScriptValue read FSourceValue write FSourceValue;
    procedure AssignValue(Source: TCasScriptValue); override;
  end;

  TCasScriptFloat = class;
  TCasScriptFunction = class;

  TCasScriptInteger = class(TCasScriptValue)
  private
    class procedure HandleAdd(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleSubtract(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleNegate(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);

    class procedure HandleMultiply(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleDivide(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleModulo(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandlePower(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);

    class procedure HandleMax(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleMin(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleSqr(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleSgn(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleAbs(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleRandom(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);

    class procedure HandleGreater(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleLesser(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleGreaterEq(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleLesserEq(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleEqual(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleNotEqual(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);

    class procedure ConvertFromInt(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure ConvertFromFloat(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure ConvertFromBool(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure ConvertFromString(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);

  private
    FPromoteToFloat: TCasScriptFloat;

    FValue: Int64;
    procedure SetValue(const AValue: Int64);
  public
    { Comfortable constructor to set initial Value.
      Note that the inherited constructor (without AValue parameter)
      is also fine to use, it will set value to zero. }
    constructor Create(const AWriteable: Boolean; const AValue: Int64); overload;
    constructor Create(const AWriteable: Boolean); overload; override;
    destructor Destroy; override;

    property Value: Int64 read FValue write SetValue;

    procedure AssignValue(Source: TCasScriptValue); override;

    { Returns this integer promoted to float.

      This object is kept and owned by this TCasScriptInteger instance,
      so it's valid as long as this TCasScriptInteger instance is valid.
      This allows you to safely use this (since you may have to return
      PromoteToFloat as return value of some Execute expressions,
      so it desirable that it's valid object reference). }
    function PromoteToFloat: TCasScriptFloat;
  end;

  TCasScriptFloat = class(TCasScriptValue)
  private
    class procedure HandleAdd(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleSubtract(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleMultiply(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleDivide(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleLerp(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleNegate(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleModulo(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleSin(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleCos(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleTan(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleCotan(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleArcSin(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleArcCos(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleArcTan(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleArcCotan(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleSinh(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleCosh(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleTanh(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleCotanh(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleLog2(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleLn(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleLog(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandlePower2(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleExp(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandlePower(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleSqr(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleSqrt(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleMax(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleMin(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleSgn(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleAbs(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleRandom(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleCeil(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleFloor(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleRound(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleGreater(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleLesser(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleGreaterEq(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleLesserEq(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleEqual(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleNotEqual(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);

    class procedure ConvertFromInt(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure ConvertFromFloat(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure ConvertFromBool(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure ConvertFromString(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);

  private
    FValue: Float;
    procedure SetValue(const AValue: Float);
  public
    { Comfortable constructor to set initial Value.
      Note that the inherited constructor (without AValue parameter)
      is also fine to use, it will set value to zero. }
    constructor Create(const AWriteable: Boolean; const AValue: Float); overload;
    constructor Create(const AWriteable: Boolean); overload; override;

    property Value: Float read FValue write SetValue;

    procedure AssignValue(Source: TCasScriptValue); override;
  end;

  TCasScriptBoolean = class(TCasScriptValue)
  private
    class procedure HandleOr(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleAnd(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleNot(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);

    class procedure HandleGreater(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleLesser(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleGreaterEq(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleLesserEq(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleEqual(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleNotEqual(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);

    class procedure ConvertFromInt(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure ConvertFromFloat(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure ConvertFromBool(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure ConvertFromString(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);

  private
    FValue: Boolean;
    procedure SetValue(const AValue: Boolean);
  public
    { Comfortable constructor to set initial Value.
      Note that the inherited constructor (without AValue parameter)
      is also fine to use, it will set value to false. }
    constructor Create(const AWriteable: Boolean; const AValue: Boolean); overload;
    constructor Create(const AWriteable: Boolean); overload; override;

    property Value: Boolean read FValue write SetValue;

    procedure AssignValue(Source: TCasScriptValue); override;
  end;

  TCasScriptString = class(TCasScriptValue)
  private
    class procedure HandleAdd(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);

    class procedure HandleGreater(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleLesser(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleGreaterEq(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleLesserEq(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleEqual(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleNotEqual(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);

    class procedure ConvertFromInt(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure ConvertFromFloat(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure ConvertFromBool(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure ConvertFromString(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);

    class procedure HandleWriteln(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
    class procedure HandleCharacterFromCode(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
  private
    FValue: String;
    procedure SetValue(const AValue: String);
  public
    { Comfortable constructor to set initial Value.
      Note that the inherited constructor (without AValue parameter)
      is also fine to use, it will set value to ''. }
    constructor Create(const AWriteable: Boolean; const AValue: String); overload;
    constructor Create(const AWriteable: Boolean); overload; override;

    property Value: String read FValue write SetValue;

    procedure AssignValue(Source: TCasScriptValue); override;
  end;

  TCasScriptRegisteredHandler = class;

  TCasScriptSearchArgumentClassesCache = record
    IsCache: Boolean;
    QueryHandlersByArgument: Contnrs.TObjectList;
    QueryArgumentClasses: TCasScriptValueClassArray;
    Answer: Boolean;
    AnswerArgumentIndex: Integer;
    AnswerHandler: TCasScriptRegisteredHandler;
  end;

  TCasScriptFunction = class(TCasScriptExpression)
  private
    FArgs: TCasScriptExpressionList;
    LastExecuteResult: TCasScriptValue;
    ParentOfLastExecuteResult: Boolean;

    { This is as returned by SearchFunctionClass }
    HandlersByArgument: Contnrs.TObjectList;

    { Helper variables for Execute implementation.
      Initialized in CheckArguments, to optimize: profiling shows that when
      they are intialized in Execute, this takes quite a lot of Execute time. }
    ExecuteArguments: array of TCasScriptValue;
    ExecuteArgumentClasses: TCasScriptValueClassArray;

    { Caches for SearchArgumentClasses, used to speed up Execute }
    Cache1: TCasScriptSearchArgumentClassesCache;
    Cache2: TCasScriptSearchArgumentClassesCache;
  protected
    { Used by constructor to check are args valid.
      Also, right now this gets FunctionHandlersByArgument (this way we don't
      have to search it at each TCasScriptFunction.Execute call,
      so TCasScriptFunction.Execute may work much faster).
      @raises(ECasScriptFunctionArgumentsError on invalid Args passed to
      function.) }
    procedure CheckArguments; virtual;

    function CoreExecute: TCasScriptValue; override;
  public
    { Constructor initializing Args from given TCasScriptExpressionList.
      AArgs list contents is copied, i.e. AArgs refence is not
      stored or freed by TCasScriptFunction. But items on AArags are not copied
      recursively, we copy references from AArags items, and so we become
      their owners.

      @raises(ECasScriptFunctionArgumentsError if you specified invalid
        number of arguments for this function.)
    }
    constructor Create(AArgs: TCasScriptExpressionList); overload;
    constructor Create(const AArgs: array of TCasScriptExpression); overload;
    destructor Destroy; override;

    { Long function name for user. This is possibly with spaces,
      parenthesis and other funny characters. It will be used in
      error messages and such to describe this function.

      Default implementation in this class simply returns ShortName.
      This should be suitable for most "norma" functions. }
    class function Name: String; virtual;

    { Short function name, for the parser.
      This is the name of the function for use in expressions
      like "function_name(arg_1, arg_2 ... , arg_n)".

      This can be an empty string ('') if no explicit name for this function
      exists. This is useful for operators, which are implemented
      just like normal functions (a descendant of TCasScriptFunction),
      but with a special support from parser (e.g. to turn "x + b" into
      a call to the TCasScriptAdd function). }
    class function ShortName: String; virtual; abstract;

    { Function name when used as an infix operator.

      Empty string ('') if no such name for this function.
      This is returned by default implementation of this in this class.

      This does require cooperation from the parser to actually work,
      that is you cannot simply define new operators by
      registering new TCasScriptFunction with InfixOperatorName <> ''.
      For now.

      Note that at least one of ShortName and InfixOperatorName
      must not be empty.

      The only exception is the TCasScriptNegate function, that is neither
      infix operator nor a usual function that must be specified
      as "function_name(arguments)". So this is an exception,
      and if there will be a need, I shall fix this (probably
      by introducing some third field, like PrefixOperatorName ?)

      Note 2 things:

      @orderedList(
        @item(
          Function that can be used as infix operator (i.e. has
          InfixOperatorName <> '') is not necessary binary operator,
          i.e. InfixOperatorName <> ''  does not determine the value of
          ArgsCount. This way I was able to define infix operators
          +, -, * etc. that take any number of arguments and operators
          like ^ and > that always take 2 arguments.)

        @item(
          Function may have both ShortName <> '' and InfixOperatorName <> ''.
          E.g. TCasScriptPower can be used as "Power(3, 1.5)" or "3 ^ 1.5".)
      ) }
    class function InfixOperatorName: String; virtual;

    { Specify which arguments are calculated before function handler
      is called.

      If = -1 (default value returned by implementation
      in this class) then all arguments are greedily calculated,
      which simply means that all arguments are calculated before
      executing function handler. This is the usual and expected
      behavior of normal functions. It's also a prerequisite
      for most of overloaded things to work, since we need to know
      types of @italic(calculated) arguments (TCasScriptValue classes)
      before we choose overloaded handler for function.

      If this is >= 0, then arguments with index >= of this will not
      be calculated before handler execution.
      Since their type is unknown, they will match any type in
      handler's ArgumentClasses.
      Your handler will receive @nil in their places, and is responsible
      for calling their Execute on it's own if needed.

      This is particularly suited for implementing control-flow
      instructions, like "if" and "while", as normal functions
      inside CastleScript. For example, "if" will have
      GreedyArgumentsCalculation = 1, so the first argument (condition)
      will be calculated, but the execution of 2nd or 3rd argument
      ("then" code or "else" code) will be left to the handler. }
    class function GreedyArgumentsCalculation: Integer; virtual;

    { Which arguments should be assignable by this function.

      Default implementation in TCasScriptFunction just returns @false
      always. If you're making a function that changes it's argument
      (like assignment operator, or vector_set, array_set and such)
      you want to override this.

      This is actually checked by CheckArguments, called from
      constructors. }
    class function ArgumentMustBeAssignable(const Index: Integer): Boolean; virtual;

    { Function arguments. Don't modify this list after function is created
      (although you can modify values inside arguments). }
    property Args: TCasScriptExpressionList read FArgs;
  end;

  TCasScriptFunctionClass = class of TCasScriptFunction;

  { Calculate result on given function arguments Arguments.
    Place result in AResult.

    The current function is also passed here, although usually you don't need it
    (you already get a list of calculated Arguments, and you should
    register different procedures for different TCasScriptFunction classes,
    so you know what operation on arguments should be done).
    For functions when GreedyArgumentsCalculation >= 0, it may be useful
    to directly access AFunction.Args.

    If needed, previous value of AResult should be freed and new created.
    If current AResult is <> nil and it's of appropriate class,
    you may also reuse it and only change it's fields
    (this is helpful, to avoid many creations/destroying
    of class instances while calculating an expression many times).
    CreateValueIfNeeded may be helpful for implementing this. }
  TCasScriptFunctionHandler = procedure (
    AFunction: TCasScriptFunction;
    const Arguments: array of TCasScriptValue;
    var AResult: TCasScriptValue;
    var ParentOfResult: Boolean) of object;

  TCasScriptSequence = class(TCasScriptFunction)
  private
    class procedure HandleSequence(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
  public
    class function Name: String; override;
    class function ShortName: String; override;
    class function InfixOperatorName: String; override;
  end;

  { CastleScript assignment operator. This is a special function,
    that must have TCasScriptValue (with Writeable = true) as it's 1st argument. }
  TCasScriptAssignment = class(TCasScriptFunction)
  private
    class procedure HandleAssignment(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
  public
    class function Name: String; override;
    class function ShortName: String; override;
    class function InfixOperatorName: String; override;
    class function ArgumentMustBeAssignable(const Index: Integer): Boolean; override;
  end;

  TCasScriptIf = class(TCasScriptFunction)
  private
    class procedure HandleIf(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
  public
    class function ShortName: String; override;
    class function GreedyArgumentsCalculation: Integer; override;
  end;

  TCasScriptWhen = class(TCasScriptFunction)
  private
    class procedure HandleWhen(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
  public
    class function ShortName: String; override;
    class function GreedyArgumentsCalculation: Integer; override;
  end;

  TCasScriptWhile = class(TCasScriptFunction)
  private
    class procedure HandleWhile(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
  public
    class function ShortName: String; override;
    class function GreedyArgumentsCalculation: Integer; override;
  end;

  TCasScriptFor = class(TCasScriptFunction)
  private
    class procedure HandleFor(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
  public
    class function ShortName: String; override;
    class function GreedyArgumentsCalculation: Integer; override;
    class function ArgumentMustBeAssignable(const Index: Integer): Boolean; override;
  end;

  TCasScriptCoalesce = class(TCasScriptFunction)
  private
    class procedure HandleCoalesce(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
  public
    class function ShortName: String; override;
    class function GreedyArgumentsCalculation: Integer; override;
  end;

  TCasScriptRegisteredHandler = class
  private
    FHandler: TCasScriptFunctionHandler;
    FFunctionClass: TCasScriptFunctionClass;
    FArgumentClasses: TCasScriptValueClassArray;
    FVariableArgumentsCount: Boolean;
  public
    constructor Create(
      AHandler: TCasScriptFunctionHandler;
      AFunctionClass: TCasScriptFunctionClass;
      const AArgumentClasses: TCasScriptValueClassArray;
      const AVariableArgumentsCount: Boolean);
    property Handler: TCasScriptFunctionHandler read FHandler;
    property FunctionClass: TCasScriptFunctionClass read FFunctionClass;
    property ArgumentClasses: TCasScriptValueClassArray read FArgumentClasses;

    { Is the handler able to receive any number of arguments.

      If yes, then the last argument class
      may be repeated any number of times (but must occur
      at least once). That is, the ArgumentClasses array
      dictates the required arguments, and more arguments are allowed.
      Note that this means that at least one argument
      must be allowed (we have to know the argument class that can
      be repeated at the end), otherwise the handler will not be able to receive
      variable number of arguments anyway. }
    property VariableArgumentsCount: Boolean read FVariableArgumentsCount;
  end;

  { This specifies for each type combination (array of TCasScriptValue classes)
    and for each function (TCasScriptFunction class) how they should
    be handled. You can think of this as a table that has a handler
    for each possible TCasScriptValue sequence and TCasScriptFunction
    combination.

    The idea is to allow programmer to extend KambiScipt by

    @orderedList(
      @item(Defining new types of values for CastleScript:
        add new TCasScriptValue class, and create handlers for known
        functions to handle this type.

        It may be comfortable to place these handlers as private methods
        within your new TCasScriptValue descendant, although this is your
        private decision.)

      @item(Defining new functions for CastleScript:
        add new TCasScriptFunction class, and create handlers for known
        values to be handled by this function.

        It may be comfortable to place these handlers as private methods
        within your new TCasScriptFunction descendant, although this is your
        private decision.)
    )

    You have a guarantee that every registered here Handler will be called
    only with AFunction of registstered type and all Arguments
    matching the array of registered types and satisfying
    VariableArgumentsCount setting.

    As a bonus, this also provides a list of all usable function classes.
    That's because you have to register at least one handler for each
    TCasScriptFunction descendant to make this function actually usable,
    so we know about it here. }
  TCasScriptFunctionHandlers = class
  private
    { This is a list of another TObjectList lists.

      Each nested list has only TCasScriptRegisteredHandler items.
      It always has at least one item.
      Each nested list has only equal FunctionClass values. }
    FHandlersByFunction: Contnrs.TObjectList;

    function SearchFunctionClass(
      FunctionClass: TCasScriptFunctionClass;
      out FunctionIndex: Integer;
      out HandlersByArgument: Contnrs.TObjectList): Boolean; overload;
    function SearchFunctionClass(
      FunctionClass: TCasScriptFunctionClass;
      out HandlersByArgument: Contnrs.TObjectList): Boolean; overload;

    function SearchArgumentClasses(
      HandlersByArgument: Contnrs.TObjectList;
      const ArgumentClasses: TCasScriptValueClassArray;
      out ArgumentIndex: Integer;
      out Handler: TCasScriptRegisteredHandler): Boolean; overload;
    function SearchArgumentClasses(
      HandlersByArgument: Contnrs.TObjectList;
      const ArgumentClasses: TCasScriptValueClassArray;
      out Handler: TCasScriptRegisteredHandler): Boolean; overload;

    { This uses Cache to speed up SearchArgumentClasses.
      The cache remembers last HandlersByArgument, ArgumentClasses,
      and answer for them (if @true). Use this if you suspect that
      SearchArgumentClasses will be called many times with the same
      HandlersByArgument, ArgumentClasses --- then this will use cache
      to give answer much faster. }
    function SearchArgumentClasses(
      HandlersByArgument: Contnrs.TObjectList;
      const ArgumentClasses: TCasScriptValueClassArray;
      out Handler: TCasScriptRegisteredHandler;
      var Cache: TCasScriptSearchArgumentClassesCache): Boolean; overload;
  public
    constructor Create;
    destructor Destroy; override;

    procedure RegisterHandler(
      AHandler: TCasScriptFunctionHandler;
      AFunctionClass: TCasScriptFunctionClass;
      const AArgumentClasses: array of TCasScriptValueClass;
      const AVariableArgumentsCount: Boolean);

    { Search for function class with matching ShortName.
      Returns @nil if not found. }
    function SearchFunctionShortName(const AShortName: String): TCasScriptFunctionClass;
  end;

  ECasScriptFunctionArgumentsError = class(ECasScriptError);
  ECasScriptFunctionNoHandler = class(ECasScriptError);

  { CastleScript user function definition.

    Not to be confused with TCasScriptFunction: TCasScriptFunction is
    an internal, built-in function or operator. This class represents
    functions defined by user. }
  TCasScriptUserFunction = class
  private
    FName: String;
    FParameters: TCasScriptValueList;
    FBody: TCasScriptExpression;
  public
    constructor Create;
    destructor Destroy; override;

    property Name: String read FName write FName;

    { List of function parameters.

      Note that they are also referenced inside function Expression,
      so you simply change them to set value of this parameter within
      whole function body.

      These are always fresh variables, not referenced anywhere outside
      of Body. This means that they are owned (always, regardless of
      OwnedByParentExpression) by this class.

      They must always be of TCasScriptParameterValue class. }
    property Parameters: TCasScriptValueList read FParameters;

    { Function body. }
    property Body: TCasScriptExpression read FBody write FBody;
  end;

  TCasScriptUserFunctionList = class({$ifdef CASTLE_OBJFPC}specialize{$endif} TObjectList<TCasScriptUserFunction>)
    function IndexOfName(const FunctionName: String): Integer;
  end;

  ECasScriptMissingFunction = class(ECasScriptError);

  TCasScriptProgram = class
  private
    FFunctions: TCasScriptUserFunctionList;
    FEnvironment: TCasScriptEnvironment;
  public
    constructor Create;
    destructor Destroy; override;

    property Functions: TCasScriptUserFunctionList read FFunctions;

    { Execute a user-defined function (from Functions list of this program).

      @unorderedList(
        @item(Looks for given FunctionName.

          IgnoreMissingFunction says what to do in case of missing function:
          if true, it will be simply ignored (ExecuteFunction will
          silently do nothng). If false (default)
          then we will raise exception ECasScriptMissingFunction.)

        @item(Sets function parameters to given values
         (number of parameters must match, otherwise ECasScriptError).
         Values from your parameters are set as our parameters
         TCasScriptParameterValue.SourceValue, so script can read and write
         your values.)

        @item(Finally executes function body.)
      )
    }
    procedure ExecuteFunction(const FunctionName: String;
      const Parameters: array of TCasScriptValue;
      const IgnoreMissingFunction: Boolean = false);

    { Environment (outside information) for this program.

      This will be created and is owned by this TCasScriptProgram instance.
      You should take care to copy this reference to all expressions
      within this program (for example ParseProgram does this),
      this way all expressions share the same Environment instance. }
    property Environment: TCasScriptEnvironment read FEnvironment write FEnvironment;
  end;

function FunctionHandlers: TCasScriptFunctionHandlers;

{ Make sure Value is assigned and of NeededClass.
  If Value is not assigned, or is not exactly of NeededClass,
  it will be freed and new will be created. }
procedure CreateValueIfNeeded(var Value: TCasScriptValue;
  var ParentOfValue: Boolean;
  NeededClass: TCasScriptValueClass);

var
  { Global method to output messages done by CastleScript @code(writeln())
    function. If not assigned, we will use CastleLog.WritelnLog. }
  OnScriptMessage: TCasScriptMessage;

  { In case of warnings/errors, output more verbose information
    about the script in which it occurred. }
  ScriptVerboseMessages: Boolean;

implementation

uses CastleScriptCoreFunctions, CastleLog;

{ TCasScriptExpression ------------------------------------------------------- }

procedure TCasScriptExpression.FreeByParentExpression;
begin
  if (Self <> nil) and
      ( (not (Self is TCasScriptValue)) or
        TCasScriptValue(Self).OwnedByParentExpression ) then
    Free;
end;

function TCasScriptExpression.Execute: TCasScriptValue;
begin
  try
    Result := CoreExecute;

    { Force raising pending exceptions by FP calculations }
    // on Nintendo Switch, this raises errors from previous innocent calculations
    {$ifndef CASTLE_NINTENDO_SWITCH}
    ClearExceptions(true);
    {$endif}
  except
    { Convert EIntError and EMathError to ECasScriptAnyMathError }
    on E: EIntError do
      raise ECasScriptAnyMathError.CreateFmt('Integer error %s: %s',
        [E.ClassName, E.Message]);
    on E: EMathError do
      raise ECasScriptAnyMathError.CreateFmt('Math error %s: %s',
        [E.ClassName, E.Message]);
  end;

  { In case some code will mask exceptions (and for cpui386 or cpux86_64,
    the OpenGL units must mask exceptions) then we need to check
    IsNan / IsInfinite. }
  {$I norqcheckbegin.inc}
  if (Result is TCasScriptFloat) and
     ( IsNan(TCasScriptFloat(Result).Value) or
       IsInfinite(TCasScriptFloat(Result).Value) ) then
    raise ECasScriptAnyMathError.Create('Floating point error');
  {$I norqcheckend.inc}
end;

function TCasScriptExpression.TryExecuteMath: TCasScriptValue;
begin
  try
    Result := Execute;
  except
    on ECasScriptAnyMathError do
      Result := nil;
  end;
end;

function TCasScriptExpression.AsFloat(const ADefaultValue: Float): Float;
var
  Res: TCasScriptValue;
begin
  try
    Res := Execute;
  except
    on E: ECasScriptError do
    begin
      WritelnWarning('CastleScript', 'Error when executing CastleScript expression: ' + E.Message);
      Result := ADefaultValue;
      Exit;
    end;
  end;

  if Res is TCasScriptFloat then
    Result := TCasScriptFloat(Res).Value else
  begin
    WritelnWarning('CastleScript', 'CastleScript expression result is not float');
    Result := ADefaultValue;
  end;
end;

function TCasScriptExpression.AsInt(const ADefaultValue: Int64): Int64;
var
  Res: TCasScriptValue;
begin
  try
    Res := Execute;
  except
    on E: ECasScriptError do
    begin
      WritelnWarning('CastleScript', 'Error when executing CastleScript expression: ' + E.Message);
      Result := ADefaultValue;
      Exit;
    end;
  end;

  if Res is TCasScriptInteger then
    Result := TCasScriptInteger(Res).Value else
  begin
    WritelnWarning('CastleScript', 'CastleScript expression result is not int');
    Result := ADefaultValue;
  end;
end;

function TCasScriptExpression.AsString(const ADefaultValue: String): String;
var
  Res: TCasScriptValue;
begin
  try
    Res := Execute;
  except
    on E: ECasScriptError do
    begin
      WritelnWarning('CastleScript', 'Error when executing CastleScript expression: ' + E.Message);
      Result := ADefaultValue;
      Exit;
    end;
  end;

  if Res is TCasScriptString then
    Result := TCasScriptString(Res).Value else
  begin
    WritelnWarning('CastleScript', 'CastleScript expression result is not string');
    Result := ADefaultValue;
  end;
end;

function TCasScriptExpression.AsBool(const ADefaultValue: Boolean): Boolean;
var
  Res: TCasScriptValue;
begin
  try
    Res := Execute;
  except
    on E: ECasScriptError do
    begin
      WritelnWarning('CastleScript', 'Error when executing CastleScript expression: ' + E.Message);
      Result := ADefaultValue;
      Exit;
    end;
  end;

  if Res is TCasScriptBoolean then
    Result := TCasScriptBoolean(Res).Value else
  begin
    WritelnWarning('CastleScript', 'CastleScript expression result is not Boolean');
    Result := ADefaultValue;
  end;
end;

{ TCasScriptExpressionList -------------------------------------------------- }

procedure TCasScriptExpressionList.AddArray(const A: array of TCasScriptExpression);
begin
  AddRange(A);
end;

procedure TCasScriptExpressionList.AddList(const Source: TCasScriptExpressionList);
begin
  AddRange(Source);
end;

procedure TCasScriptExpressionList.FreeContentsByParentExpression;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
  begin
    Items[I].FreeByParentExpression;
    Items[I] := nil;
  end;
end;

{ TCasScriptValue ------------------------------------------------------------ }

constructor TCasScriptValue.Create(const AWriteable: Boolean);
begin
  inherited Create;
  FOwnedByParentExpression := true;
  FWriteable := AWriteable;
end;

function TCasScriptValue.CoreExecute: TCasScriptValue;
begin
  { Since we own Execute result, we can simply return self here. }
  Result := Self;
end;

{ TCasScriptValueList ------------------------------------------------------- }

procedure TCasScriptValueList.AddArray(const A: array of TCasScriptValue);
begin
  AddRange(A);
end;

function TCasScriptValueList.FindName(const VariableName: String): TCasScriptValue;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    if Items[I].Name = VariableName then
      Exit(Items[I]);
  Result := nil;
end;

{ TCasScriptParameterValue --------------------------------------------------- }

function TCasScriptParameterValue.CoreExecute: TCasScriptValue;
begin
  Result := SourceValue.CoreExecute;
end;

procedure TCasScriptParameterValue.AssignValue(Source: TCasScriptValue);
begin
  SourceValue.AssignValue(Source);
end;

{ TCasScriptInteger ---------------------------------------------------------- }

constructor TCasScriptInteger.Create(const AWriteable: Boolean; const AValue: Int64);
begin
  Create(AWriteable);
  Value := AValue;
end;

constructor TCasScriptInteger.Create(const AWriteable: Boolean);
begin
  inherited Create(AWriteable);
end;

destructor TCasScriptInteger.Destroy;
begin
  FPromoteToFloat.FreeByParentExpression;
  inherited;
end;

function TCasScriptInteger.PromoteToFloat: TCasScriptFloat;
begin
  if FPromoteToFloat = nil then
    FPromoteToFloat := TCasScriptFloat.Create(false, Value) else
    FPromoteToFloat.Value := Value;
  Result := FPromoteToFloat;
end;

class procedure TCasScriptInteger.HandleAdd(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
var
  I: Integer;
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptInteger);
  { The function allows only >= 1 arguments, and this handler is
    registered only for TCasScriptInteger values, so we can safely take
    the first arg as TCasScriptInteger. }
  TCasScriptInteger(AResult).Value := TCasScriptInteger(Arguments[0]).Value;
  for I := 1 to Length(Arguments) - 1 do
    TCasScriptInteger(AResult).Value :=
      TCasScriptInteger(AResult).Value + TCasScriptInteger(Arguments[I]).Value;
end;

class procedure TCasScriptInteger.HandleSubtract(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
var
  I: Integer;
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptInteger);
  TCasScriptInteger(AResult).Value := TCasScriptInteger(Arguments[0]).Value;
  for I := 1 to Length(Arguments) - 1 do
    TCasScriptInteger(AResult).Value :=
      TCasScriptInteger(AResult).Value - TCasScriptInteger(Arguments[I]).Value;
end;

class procedure TCasScriptInteger.HandleMultiply(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
var
  I: Integer;
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptInteger);
  TCasScriptInteger(AResult).Value := TCasScriptInteger(Arguments[0]).Value;
  for I := 1 to Length(Arguments) - 1 do
    TCasScriptInteger(AResult).Value :=
      TCasScriptInteger(AResult).Value * TCasScriptInteger(Arguments[I]).Value;
end;

class procedure TCasScriptInteger.HandleDivide(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
var
  I: Integer;
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptInteger);
  TCasScriptInteger(AResult).Value := TCasScriptInteger(Arguments[0]).Value;
  for I := 1 to Length(Arguments) - 1 do
    TCasScriptInteger(AResult).Value :=
      TCasScriptInteger(AResult).Value div TCasScriptInteger(Arguments[I]).Value;
end;

class procedure TCasScriptInteger.HandleNegate(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptInteger);
  TCasScriptInteger(AResult).Value := - TCasScriptInteger(Arguments[0]).Value;
end;

class procedure TCasScriptInteger.HandleModulo(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptInteger);
  TCasScriptInteger(AResult).Value :=
    TCasScriptInteger(Arguments[0]).Value mod
    TCasScriptInteger(Arguments[1]).Value;
end;

class procedure TCasScriptInteger.HandlePower(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptInteger);
  if (TCasScriptInteger(Arguments[0]).Value < 0) or
     (TCasScriptInteger(Arguments[1]).Value < 0) then
    raise ECasScriptError.Create('Power function on integer operands expects both arguments to be >= 0');

  TCasScriptInteger(AResult).Value := NatNatPower(
    TCasScriptInteger(Arguments[0]).Value,
    TCasScriptInteger(Arguments[1]).Value );
end;

class procedure TCasScriptInteger.HandleSqr(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptInteger);
  TCasScriptInteger(AResult).Value := Sqr( TCasScriptInteger(Arguments[0]).Value );
end;

class procedure TCasScriptInteger.HandleMax(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
var
  I: Integer;
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptInteger);
  TCasScriptInteger(AResult).Value := TCasScriptInteger(Arguments[0]).Value;
  for I := 1 to Length(Arguments) - 1 do
    TCasScriptInteger(AResult).Value := Max(
      TCasScriptInteger(AResult).Value, TCasScriptInteger(Arguments[I]).Value);
end;

class procedure TCasScriptInteger.HandleMin(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
var
  I: Integer;
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptInteger);
  TCasScriptInteger(AResult).Value := TCasScriptInteger(Arguments[0]).Value;
  for I := 1 to Length(Arguments) - 1 do
    TCasScriptInteger(AResult).Value := Min(
      TCasScriptInteger(AResult).Value, TCasScriptInteger(Arguments[I]).Value);
end;

class procedure TCasScriptInteger.HandleSgn(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptInteger);
  TCasScriptInteger(AResult).Value := Sign( TCasScriptInteger(Arguments[0]).Value );
end;

class procedure TCasScriptInteger.HandleAbs(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptInteger);
  TCasScriptInteger(AResult).Value := Abs( TCasScriptInteger(Arguments[0]).Value );
end;

class procedure TCasScriptInteger.HandleRandom(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptInteger);
  TCasScriptInteger(AResult).Value := Random( TCasScriptInteger(Arguments[0]).Value );
end;

class procedure TCasScriptInteger.HandleGreater(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptBoolean);
  TCasScriptBoolean(AResult).Value :=
    TCasScriptInteger(Arguments[0]).Value >
    TCasScriptInteger(Arguments[1]).Value;
end;

class procedure TCasScriptInteger.HandleLesser(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptBoolean);
  TCasScriptBoolean(AResult).Value :=
    TCasScriptInteger(Arguments[0]).Value <
    TCasScriptInteger(Arguments[1]).Value;
end;

class procedure TCasScriptInteger.HandleGreaterEq(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptBoolean);
  TCasScriptBoolean(AResult).Value :=
    TCasScriptInteger(Arguments[0]).Value >=
    TCasScriptInteger(Arguments[1]).Value;
end;

class procedure TCasScriptInteger.HandleLesserEq(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptBoolean);
  TCasScriptBoolean(AResult).Value :=
    TCasScriptInteger(Arguments[0]).Value <=
    TCasScriptInteger(Arguments[1]).Value;
end;

class procedure TCasScriptInteger.HandleEqual(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptBoolean);
  TCasScriptBoolean(AResult).Value :=
    TCasScriptInteger(Arguments[0]).Value =
    TCasScriptInteger(Arguments[1]).Value;
end;

class procedure TCasScriptInteger.HandleNotEqual(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptBoolean);
  TCasScriptBoolean(AResult).Value :=
    TCasScriptInteger(Arguments[0]).Value <>
    TCasScriptInteger(Arguments[1]).Value;
end;

class procedure TCasScriptInteger.ConvertFromInt(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  if ParentOfResult then
    AResult.FreeByParentExpression else
    AResult := nil;

  AResult := Arguments[0];
  Assert(AResult is TCasScriptInteger);
  ParentOfResult := false;
end;

class procedure TCasScriptInteger.ConvertFromFloat(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
var
  F: Float;
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptInteger);
  { Can't use Int function, as it returns float value }

  F := TCasScriptFloat(Arguments[0]).Value;
  if F >= 0 then
    TCasScriptInteger(AResult).Value := Floor(F) else
    TCasScriptInteger(AResult).Value := Ceil(F);
end;

class procedure TCasScriptInteger.ConvertFromBool(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
var
  BoolTo01: array [Boolean] of Int64 = (0, 1);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptInteger);
  TCasScriptInteger(AResult).Value := BoolTo01[TCasScriptBoolean(Arguments[0]).Value];
end;

class procedure TCasScriptInteger.ConvertFromString(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptInteger);
  try
    TCasScriptInteger(AResult).Value := StrToInt64(TCasScriptString(Arguments[0]).Value);
  except
    on E: EConvertError do
      { Change EConvertError to ECasScriptError }
      raise ECasScriptError.CreateFmt('Error when converting string "%s" to integer: %s',
        [TCasScriptString(Arguments[0]).Value, E.Message]);
  end;
end;

procedure TCasScriptInteger.AssignValue(Source: TCasScriptValue);
begin
  if Source is TCasScriptInteger then
    Value := TCasScriptInteger(Source).Value else
    raise ECasScriptAssignError.CreateFmt('Assignment from %s to %s not possible', [Source.ClassName, ClassName]);
end;

procedure TCasScriptInteger.SetValue(const AValue: Int64);
begin
  FValue := AValue;
  ValueAssigned := true;
end;

{ TCasScriptFloat ------------------------------------------------------- }

constructor TCasScriptFloat.Create(const AWriteable: Boolean; const AValue: Float);
begin
  Create(AWriteable);
  Value := AValue;
end;

constructor TCasScriptFloat.Create(const AWriteable: Boolean);
begin
  inherited Create(AWriteable);
end;

class procedure TCasScriptFloat.HandleAdd(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
var
  I: Integer;
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  { The function allows only >= 1 arguments, and this handler is
    registered only for TCasScriptFloat values, so we can safely take
    the first arg as TCasScriptFloat. }
  TCasScriptFloat(AResult).Value := TCasScriptFloat(Arguments[0]).Value;
  for I := 1 to Length(Arguments) - 1 do
    TCasScriptFloat(AResult).Value :=
      TCasScriptFloat(AResult).Value + TCasScriptFloat(Arguments[I]).Value;
end;

class procedure TCasScriptFloat.HandleSubtract(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
var
  I: Integer;
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value := TCasScriptFloat(Arguments[0]).Value;
  for I := 1 to Length(Arguments) - 1 do
    TCasScriptFloat(AResult).Value :=
      TCasScriptFloat(AResult).Value - TCasScriptFloat(Arguments[I]).Value;
end;

class procedure TCasScriptFloat.HandleMultiply(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
var
  I: Integer;
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value := TCasScriptFloat(Arguments[0]).Value;
  for I := 1 to Length(Arguments) - 1 do
    TCasScriptFloat(AResult).Value :=
      TCasScriptFloat(AResult).Value * TCasScriptFloat(Arguments[I]).Value;
end;

class procedure TCasScriptFloat.HandleDivide(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
var
  I: Integer;
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value := TCasScriptFloat(Arguments[0]).Value;
  for I := 1 to Length(Arguments) - 1 do
    TCasScriptFloat(AResult).Value :=
      TCasScriptFloat(AResult).Value / TCasScriptFloat(Arguments[I]).Value;
end;

class procedure TCasScriptFloat.HandleLerp(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value := Lerp(
    TCasScriptFloat(Arguments[0]).Value,
    TCasScriptFloat(Arguments[1]).Value,
    TCasScriptFloat(Arguments[2]).Value);
end;

class procedure TCasScriptFloat.HandleNegate(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value := - TCasScriptFloat(Arguments[0]).Value;
end;

class procedure TCasScriptFloat.HandleModulo(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value :=
    TCasScriptFloat(Arguments[0]).Value -
    Floor( TCasScriptFloat(Arguments[0]).Value /
           TCasScriptFloat(Arguments[1]).Value )
    * TCasScriptFloat(Arguments[1]).Value;
end;

class procedure TCasScriptFloat.HandleSin(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value := Sin( TCasScriptFloat(Arguments[0]).Value );
end;

class procedure TCasScriptFloat.HandleCos(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value := Cos( TCasScriptFloat(Arguments[0]).Value );
end;

class procedure TCasScriptFloat.HandleTan(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value := Tan( TCasScriptFloat(Arguments[0]).Value );
end;

class procedure TCasScriptFloat.HandleCotan(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value := CastleCoTan( TCasScriptFloat(Arguments[0]).Value );
end;

class procedure TCasScriptFloat.HandleArcSin(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value := ArcSin( TCasScriptFloat(Arguments[0]).Value );
end;

class procedure TCasScriptFloat.HandleArcCos(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value := ArcCos( TCasScriptFloat(Arguments[0]).Value );
end;

class procedure TCasScriptFloat.HandleArcTan(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value := ArcTan( TCasScriptFloat(Arguments[0]).Value );
end;

class procedure TCasScriptFloat.HandleArcCotan(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value := ArcCot( TCasScriptFloat(Arguments[0]).Value );
end;

class procedure TCasScriptFloat.HandleSinh(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value := SinH( TCasScriptFloat(Arguments[0]).Value );
end;

class procedure TCasScriptFloat.HandleCosh(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value := CosH( TCasScriptFloat(Arguments[0]).Value );
end;

class procedure TCasScriptFloat.HandleTanh(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value := TanH( TCasScriptFloat(Arguments[0]).Value );
end;

class procedure TCasScriptFloat.HandleCotanh(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value := 1 / TanH( TCasScriptFloat(Arguments[0]).Value );
end;

class procedure TCasScriptFloat.HandleLog2(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value := Log2( TCasScriptFloat(Arguments[0]).Value );
end;

class procedure TCasScriptFloat.HandleLn(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value := Ln( TCasScriptFloat(Arguments[0]).Value );
end;

class procedure TCasScriptFloat.HandleLog(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value := Logn( TCasScriptFloat(Arguments[0]).Value,
                                          TCasScriptFloat(Arguments[1]).Value );
end;

class procedure TCasScriptFloat.HandlePower2(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value := Power(2, TCasScriptFloat(Arguments[0]).Value);
end;

class procedure TCasScriptFloat.HandleExp(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value := Exp( TCasScriptFloat(Arguments[0]).Value );
end;

class procedure TCasScriptFloat.HandlePower(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value := Power(
    TCasScriptFloat(Arguments[0]).Value,
    TCasScriptFloat(Arguments[1]).Value );
end;

class procedure TCasScriptFloat.HandleSqr(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value := Sqr( TCasScriptFloat(Arguments[0]).Value );
end;

class procedure TCasScriptFloat.HandleSqrt(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value := Sqrt( TCasScriptFloat(Arguments[0]).Value );
end;

class procedure TCasScriptFloat.HandleMax(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
var
  I: Integer;
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value := TCasScriptFloat(Arguments[0]).Value;
  for I := 1 to Length(Arguments) - 1 do
    TCasScriptFloat(AResult).Value := Max(
      TCasScriptFloat(AResult).Value, TCasScriptFloat(Arguments[I]).Value);
end;

class procedure TCasScriptFloat.HandleMin(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
var
  I: Integer;
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value := TCasScriptFloat(Arguments[0]).Value;
  for I := 1 to Length(Arguments) - 1 do
    TCasScriptFloat(AResult).Value := Min(
      TCasScriptFloat(AResult).Value, TCasScriptFloat(Arguments[I]).Value);
end;

class procedure TCasScriptFloat.HandleSgn(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptInteger);
  TCasScriptInteger(AResult).Value := Sign( TCasScriptFloat(Arguments[0]).Value );
end;

class procedure TCasScriptFloat.HandleAbs(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value := Abs( TCasScriptFloat(Arguments[0]).Value );
end;

class procedure TCasScriptFloat.HandleRandom(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value := Random();
end;

class procedure TCasScriptFloat.HandleCeil(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptInteger);
  TCasScriptInteger(AResult).Value := Ceil( TCasScriptFloat(Arguments[0]).Value );
end;

class procedure TCasScriptFloat.HandleFloor(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptInteger);
  TCasScriptInteger(AResult).Value := Floor( TCasScriptFloat(Arguments[0]).Value );
end;

class procedure TCasScriptFloat.HandleRound(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptInteger);
  TCasScriptInteger(AResult).Value := Round( TCasScriptFloat(Arguments[0]).Value );
end;

class procedure TCasScriptFloat.HandleGreater(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptBoolean);
  TCasScriptBoolean(AResult).Value :=
    TCasScriptFloat(Arguments[0]).Value >
    TCasScriptFloat(Arguments[1]).Value;
end;

class procedure TCasScriptFloat.HandleLesser(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptBoolean);
  TCasScriptBoolean(AResult).Value :=
    TCasScriptFloat(Arguments[0]).Value <
    TCasScriptFloat(Arguments[1]).Value;
end;

class procedure TCasScriptFloat.HandleGreaterEq(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptBoolean);
  TCasScriptBoolean(AResult).Value :=
    TCasScriptFloat(Arguments[0]).Value >=
    TCasScriptFloat(Arguments[1]).Value;
end;

class procedure TCasScriptFloat.HandleLesserEq(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptBoolean);
  TCasScriptBoolean(AResult).Value :=
    TCasScriptFloat(Arguments[0]).Value <=
    TCasScriptFloat(Arguments[1]).Value;
end;

class procedure TCasScriptFloat.HandleEqual(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptBoolean);
  TCasScriptBoolean(AResult).Value :=
    TCasScriptFloat(Arguments[0]).Value =
    TCasScriptFloat(Arguments[1]).Value;
end;

class procedure TCasScriptFloat.HandleNotEqual(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptBoolean);
  TCasScriptBoolean(AResult).Value :=
    TCasScriptFloat(Arguments[0]).Value <>
    TCasScriptFloat(Arguments[1]).Value;
end;

class procedure TCasScriptFloat.ConvertFromInt(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value := TCasScriptInteger(Arguments[0]).Value;
end;

class procedure TCasScriptFloat.ConvertFromFloat(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  if ParentOfResult then
    AResult.FreeByParentExpression else
    AResult := nil;

  AResult := Arguments[0];
  Assert(AResult is TCasScriptFloat);
  ParentOfResult := false;
end;

class procedure TCasScriptFloat.ConvertFromBool(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
var
  BoolTo01: array [Boolean] of Float = (0, 1);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  TCasScriptFloat(AResult).Value := BoolTo01[TCasScriptBoolean(Arguments[0]).Value];
end;

class procedure TCasScriptFloat.ConvertFromString(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptFloat);
  try
    TCasScriptFloat(AResult).Value := StrToFloatDot(TCasScriptString(Arguments[0]).Value);
  except
    on E: EConvertError do
      { Change EConvertError to ECasScriptError }
      raise ECasScriptError.CreateFmt('Error when converting string "%s" to float: %s',
        [TCasScriptString(Arguments[0]).Value, E.Message]);
  end;
end;

procedure TCasScriptFloat.AssignValue(Source: TCasScriptValue);
begin
  if Source is TCasScriptFloat then
    Value := TCasScriptFloat(Source).Value else
  { This allows for type promotion integer->float at assignment. }
  if Source is TCasScriptInteger then
    Value := TCasScriptInteger(Source).Value else
    raise ECasScriptAssignError.CreateFmt('Assignment from %s to %s not possible', [Source.ClassName, ClassName]);
end;

procedure TCasScriptFloat.SetValue(const AValue: Float);
begin
  FValue := AValue;
  ValueAssigned := true;
end;

{ TCasScriptBoolean ---------------------------------------------------------- }

constructor TCasScriptBoolean.Create(const AWriteable: Boolean; const AValue: Boolean);
begin
  Create(AWriteable);
  Value := AValue;
end;

constructor TCasScriptBoolean.Create(const AWriteable: Boolean);
begin
  inherited Create(AWriteable);
end;

class procedure TCasScriptBoolean.HandleOr(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
var
  I: Integer;
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptBoolean);
  TCasScriptBoolean(AResult).Value := TCasScriptBoolean(Arguments[0]).Value;
  for I := 1 to Length(Arguments) - 1 do
    TCasScriptBoolean(AResult).Value :=
      TCasScriptBoolean(AResult).Value or TCasScriptBoolean(Arguments[I]).Value;
end;

class procedure TCasScriptBoolean.HandleAnd(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
var
  I: Integer;
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptBoolean);
  TCasScriptBoolean(AResult).Value := TCasScriptBoolean(Arguments[0]).Value;
  for I := 1 to Length(Arguments) - 1 do
    TCasScriptBoolean(AResult).Value :=
      TCasScriptBoolean(AResult).Value and TCasScriptBoolean(Arguments[I]).Value;
end;

class procedure TCasScriptBoolean.HandleNot(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptBoolean);
  TCasScriptBoolean(AResult).Value := not TCasScriptBoolean(Arguments[0]).Value;
end;

class procedure TCasScriptBoolean.HandleGreater(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptBoolean);
  TCasScriptBoolean(AResult).Value :=
    TCasScriptBoolean(Arguments[0]).Value >
    TCasScriptBoolean(Arguments[1]).Value;
end;

class procedure TCasScriptBoolean.HandleLesser(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptBoolean);
  TCasScriptBoolean(AResult).Value :=
    TCasScriptBoolean(Arguments[0]).Value <
    TCasScriptBoolean(Arguments[1]).Value;
end;

class procedure TCasScriptBoolean.HandleGreaterEq(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptBoolean);
  TCasScriptBoolean(AResult).Value :=
    TCasScriptBoolean(Arguments[0]).Value >=
    TCasScriptBoolean(Arguments[1]).Value;
end;

class procedure TCasScriptBoolean.HandleLesserEq(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptBoolean);
  TCasScriptBoolean(AResult).Value :=
    TCasScriptBoolean(Arguments[0]).Value <=
    TCasScriptBoolean(Arguments[1]).Value;
end;

class procedure TCasScriptBoolean.HandleEqual(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptBoolean);
  TCasScriptBoolean(AResult).Value :=
    TCasScriptBoolean(Arguments[0]).Value =
    TCasScriptBoolean(Arguments[1]).Value;
end;

class procedure TCasScriptBoolean.HandleNotEqual(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptBoolean);
  TCasScriptBoolean(AResult).Value :=
    TCasScriptBoolean(Arguments[0]).Value <>
    TCasScriptBoolean(Arguments[1]).Value;
end;

class procedure TCasScriptBoolean.ConvertFromInt(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptBoolean);
  TCasScriptBoolean(AResult).Value := TCasScriptInteger(Arguments[0]).Value <> 0;
end;

class procedure TCasScriptBoolean.ConvertFromFloat(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptBoolean);
  TCasScriptBoolean(AResult).Value := TCasScriptFloat(Arguments[0]).Value <> 0;
end;

class procedure TCasScriptBoolean.ConvertFromBool(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  if ParentOfResult then
    AResult.FreeByParentExpression else
    AResult := nil;

  AResult := Arguments[0];
  Assert(AResult is TCasScriptBoolean);
  ParentOfResult := false;
end;

class procedure TCasScriptBoolean.ConvertFromString(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
var
  S: String;
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptBoolean);
  S := LowerCase(TCasScriptString(Arguments[0]).Value);
  if S = 'false' then
    TCasScriptBoolean(AResult).Value := false else
  if S = 'true' then
    TCasScriptBoolean(AResult).Value := true else
    raise ECasScriptError.CreateFmt('Error when converting string "%s" to Boolean: invalid value, must be "false" or "true"',
      [TCasScriptString(Arguments[0]).Value]);
end;

procedure TCasScriptBoolean.AssignValue(Source: TCasScriptValue);
begin
  if Source is TCasScriptBoolean then
    Value := TCasScriptBoolean(Source).Value else
    raise ECasScriptAssignError.CreateFmt('Assignment from %s to %s not possible', [Source.ClassName, ClassName]);
end;

procedure TCasScriptBoolean.SetValue(const AValue: Boolean);
begin
  FValue := AValue;
  ValueAssigned := true;
end;

{ TCasScriptString ---------------------------------------------------------- }

constructor TCasScriptString.Create(const AWriteable: Boolean; const AValue: String);
begin
  Create(AWriteable);
  Value := AValue;
end;

constructor TCasScriptString.Create(const AWriteable: Boolean);
begin
  inherited Create(AWriteable);
end;

class procedure TCasScriptString.HandleAdd(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
var
  I: Integer;
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptString);
  { The function allows only >= 1 arguments, and this handler is
    registered only for TCasScriptString values, so we can safely take
    the first arg as TCasScriptString. }
  TCasScriptString(AResult).Value := TCasScriptString(Arguments[0]).Value;
  for I := 1 to Length(Arguments) - 1 do
    TCasScriptString(AResult).Value :=
      TCasScriptString(AResult).Value + TCasScriptString(Arguments[I]).Value;
end;

class procedure TCasScriptString.HandleGreater(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptBoolean);
  TCasScriptBoolean(AResult).Value :=
    TCasScriptString(Arguments[0]).Value >
    TCasScriptString(Arguments[1]).Value;
end;

class procedure TCasScriptString.HandleLesser(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptBoolean);
  TCasScriptBoolean(AResult).Value :=
    TCasScriptString(Arguments[0]).Value <
    TCasScriptString(Arguments[1]).Value;
end;

class procedure TCasScriptString.HandleGreaterEq(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptBoolean);
  TCasScriptBoolean(AResult).Value :=
    TCasScriptString(Arguments[0]).Value >=
    TCasScriptString(Arguments[1]).Value;
end;

class procedure TCasScriptString.HandleLesserEq(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptBoolean);
  TCasScriptBoolean(AResult).Value :=
    TCasScriptString(Arguments[0]).Value <=
    TCasScriptString(Arguments[1]).Value;
end;

class procedure TCasScriptString.HandleEqual(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptBoolean);
  TCasScriptBoolean(AResult).Value :=
    TCasScriptString(Arguments[0]).Value =
    TCasScriptString(Arguments[1]).Value;
end;

class procedure TCasScriptString.HandleNotEqual(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptBoolean);
  TCasScriptBoolean(AResult).Value :=
    TCasScriptString(Arguments[0]).Value <>
    TCasScriptString(Arguments[1]).Value;
end;

class procedure TCasScriptString.ConvertFromInt(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptString);
  TCasScriptString(AResult).Value := IntToStr(TCasScriptInteger(Arguments[0]).Value);
end;

class procedure TCasScriptString.ConvertFromFloat(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptString);
  TCasScriptString(AResult).Value := FloatToStrDot(TCasScriptFloat(Arguments[0]).Value);
end;

class procedure TCasScriptString.ConvertFromBool(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
var
  BoolTo01: array [Boolean] of String = ('false', 'true');
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptString);
  TCasScriptString(AResult).Value := BoolTo01[TCasScriptBoolean(Arguments[0]).Value];
end;

class procedure TCasScriptString.ConvertFromString(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  if ParentOfResult then
    AResult.FreeByParentExpression else
    AResult := nil;

  AResult := Arguments[0];
  Assert(AResult is TCasScriptString);
  ParentOfResult := false;
end;

class procedure TCasScriptString.HandleWriteln(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
var
  S: String;
begin
  if ParentOfResult then
    AResult.FreeByParentExpression else
    AResult := nil;

  AResult := Arguments[0];
  ParentOfResult := false;

  S := TCasScriptString(Arguments[0]).Value;

  if Assigned(OnScriptMessage) then
    OnScriptMessage(S) else
    WritelnLog('CastleScript', 'Writeln: '+ S);
end;

class procedure TCasScriptString.HandleCharacterFromCode(AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
var
  CharCode: Int64;
begin
  CreateValueIfNeeded(AResult, ParentOfResult, TCasScriptString);

  CharCode := TCasScriptInteger(Arguments[0]).Value;

  if Between(CharCode, Low(Byte), High(Byte)) then
    TCasScriptString(AResult).Value := Chr(CharCode) else
    TCasScriptString(AResult).Value := '';
end;

procedure TCasScriptString.AssignValue(Source: TCasScriptValue);
begin
  if Source is TCasScriptString then
    Value := TCasScriptString(Source).Value else
    raise ECasScriptAssignError.CreateFmt('Assignment from %s to %s not possible', [Source.ClassName, ClassName]);
end;

procedure TCasScriptString.SetValue(const AValue: String);
begin
  FValue := AValue;
  ValueAssigned := true;
end;

{ TCasScriptFunction --------------------------------------------------------- }

constructor TCasScriptFunction.Create(AArgs: TCasScriptExpressionList);
begin
  inherited Create;
  FArgs := TCasScriptExpressionList.Create(false);
  FArgs.AddRange(AArgs);
  CheckArguments;
end;

constructor TCasScriptFunction.Create(const AArgs: array of TCasScriptExpression);
begin
  inherited Create;
  FArgs := TCasScriptExpressionList.Create(false);
  FArgs.AddRange(AArgs);
  CheckArguments;
end;

procedure TCasScriptFunction.CheckArguments;
var
  I: Integer;
begin
  for I := 0 to Args.Count - 1 do
    if ArgumentMustBeAssignable(I) and
       not ( (Args[I] is TCasScriptValue) and
             TCasScriptValue(Args[I]).Writeable ) then
      raise ECasScriptFunctionArgumentsError.CreateFmt('Argument %d of function %s must be a writeable operand (but is not)',
        [I, Name]);

  if not FunctionHandlers.SearchFunctionClass(
    TCasScriptFunctionClass(Self.ClassType), HandlersByArgument) then
    raise ECasScriptFunctionNoHandler.CreateFmt('No handler defined for function "%s"', [Name]);

  SetLength(ExecuteArguments, Args.Count);
  SetLength(ExecuteArgumentClasses, Args.Count);
end;

destructor TCasScriptFunction.Destroy;
begin
  if FArgs <> nil then
  begin
    FArgs.FreeContentsByParentExpression;
    FreeAndNil(FArgs);
  end;

  if ParentOfLastExecuteResult then
    LastExecuteResult.FreeByParentExpression;
  LastExecuteResult := nil;

  inherited;
end;

class function TCasScriptFunction.Name: String;
begin
  Result := ShortName;
end;

class function TCasScriptFunction.InfixOperatorName: String;
begin
  Result := '';
end;

class function TCasScriptFunction.GreedyArgumentsCalculation: Integer;
begin
  Result := -1;
end;

class function TCasScriptFunction.ArgumentMustBeAssignable(const Index: Integer): Boolean;
begin
  Result := false;
end;

function TCasScriptFunction.CoreExecute: TCasScriptValue;

  function ArgumentClassesToStr(const A: TCasScriptValueClassArray): String;
  var
    I: Integer;
  begin
    Result := '';
    for I := 0 to Length(A) - 1 do
    begin
      if I > 0 then Result := Result + ', ';
      { A[I] = nil may happen in case of GreedyArgumentsCalculation >= 0,
        and it means then that any type of arg will be accepted. }
      if A[I] = nil then
        Result := Result + 'anything'
      else
        Result := Result + A[I].ClassName;
    end;
    Result := '(' + Result + ')';
  end;

var
  Handler: TCasScriptRegisteredHandler;
  I, GreedyArguments: Integer;
begin
  GreedyArguments := Args.Count;
  if GreedyArgumentsCalculation <> -1 then
    MinVar(GreedyArguments, GreedyArgumentsCalculation);

  { We have to calculate arguments first, to know their type,
    to decide which handler is suitable.
    Actually, we calculate only first GreedyArguments, rest is left as nil. }
  for I := 0 to GreedyArguments - 1 do
  begin
    ExecuteArguments[I] := Args[I].CoreExecute;
    ExecuteArgumentClasses[I] := TCasScriptValueClass(ExecuteArguments[I].ClassType);
  end;
  for I := GreedyArguments to Args.Count - 1 do
  begin
    ExecuteArguments[I] := nil;
    ExecuteArgumentClasses[I] := nil;
  end;

  { calculate Handler }
  if not FunctionHandlers.SearchArgumentClasses(
    HandlersByArgument, ExecuteArgumentClasses, Handler, Cache1) then
  begin
    { try promoting integer arguments to float, see if it will work then }
    for I := 0 to Length(ExecuteArgumentClasses) - 1 do
      if (ExecuteArgumentClasses[I] <> nil) and
         (ExecuteArgumentClasses[I].InheritsFrom(TCasScriptInteger)) then
        ExecuteArgumentClasses[I] := TCasScriptFloat;

    if FunctionHandlers.SearchArgumentClasses(
      HandlersByArgument, ExecuteArgumentClasses, Handler, Cache2) then
    begin
      { So I found a handler, that will be valid if all integer args will
        get promoted to float. Cool, let's do it.

        I use PromoteToFloat method, that will keep it's result valid
        for some time, since (depending on function handler) we may
        return PromoteToFloat result to the user. }
      for I := 0 to Length(ExecuteArguments) - 1 do
        if (ExecuteArguments[I] <> nil) and
           (ExecuteArguments[I] is TCasScriptInteger) then
          ExecuteArguments[I] := TCasScriptInteger(ExecuteArguments[I]).PromoteToFloat;
    end else
      raise ECasScriptFunctionNoHandler.CreateFmt('Function "%s" is not defined for this combination of arguments: %s',
        [Name, ArgumentClassesToStr(ExecuteArgumentClasses)]);
  end;

  Handler.Handler(Self, ExecuteArguments, LastExecuteResult, ParentOfLastExecuteResult);

  Result := LastExecuteResult;
end;

{ TCasScriptRegisteredHandler ------------------------------------------------ }

constructor TCasScriptRegisteredHandler.Create(
  AHandler: TCasScriptFunctionHandler;
  AFunctionClass: TCasScriptFunctionClass;
  const AArgumentClasses: TCasScriptValueClassArray;
  const AVariableArgumentsCount: Boolean);
begin
  FHandler := AHandler;
  FFunctionClass := AFunctionClass;
  FArgumentClasses := AArgumentClasses;
  FVariableArgumentsCount := AVariableArgumentsCount;
end;

{ TCasScriptSequence --------------------------------------------------------- }

class function TCasScriptSequence.Name: String;
begin
  Result := 'sequence (;)';
end;

class function TCasScriptSequence.ShortName: String;
begin
  Result := '';
end;

class function TCasScriptSequence.InfixOperatorName: String;
begin
  Result := ';';
end;

class procedure TCasScriptSequence.HandleSequence(
  AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  if ParentOfResult then
    AResult.FreeByParentExpression else
    AResult := nil;

  AResult := Arguments[High(Arguments)];
  ParentOfResult := false;
end;

{ TCasScriptAssignment --------------------------------------------------------- }

class function TCasScriptAssignment.Name: String;
begin
  Result := 'assignment (:=)';
end;

class function TCasScriptAssignment.ShortName: String;
begin
  Result := '';
end;

class function TCasScriptAssignment.InfixOperatorName: String;
begin
  Result := ':=';
end;

class procedure TCasScriptAssignment.HandleAssignment(
  AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  if ParentOfResult then
    AResult.FreeByParentExpression else
    AResult := nil;

  (Arguments[0] as TCasScriptValue).AssignValue(Arguments[1]);

  AResult := Arguments[0] as TCasScriptValue;
  ParentOfResult := false;
end;

class function TCasScriptAssignment.ArgumentMustBeAssignable(const Index: Integer): Boolean;
begin
  Result := Index = 0;
end;

{ TCasScriptIf --------------------------------------------------------- }

class function TCasScriptIf.ShortName: String;
begin
  Result := 'if';
end;

class procedure TCasScriptIf.HandleIf(
  AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  if ParentOfResult then
    AResult.FreeByParentExpression;
  AResult := nil;
  ParentOfResult := false;

  if TCasScriptBoolean(Arguments[0]).Value then
    AResult := AFunction.Args[1].CoreExecute else
    AResult := AFunction.Args[2].CoreExecute;
end;

class function TCasScriptIf.GreedyArgumentsCalculation: Integer;
begin
  Result := 1;
end;

{ TCasScriptWhen --------------------------------------------------------- }

class function TCasScriptWhen.ShortName: String;
begin
  Result := 'when';
end;

class procedure TCasScriptWhen.HandleWhen(
  AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
begin
  if ParentOfResult then
    AResult.FreeByParentExpression;
  AResult := nil;
  ParentOfResult := false;

  if TCasScriptBoolean(Arguments[0]).Value then
    AResult := AFunction.Args[1].CoreExecute else
  begin
    { "when" returns simple const false on "else" condition }
    AResult := TCasScriptBoolean.Create(false);
    ParentOfResult := true;
  end;
end;

class function TCasScriptWhen.GreedyArgumentsCalculation: Integer;
begin
  Result := 1;
end;

{ TCasScriptWhile --------------------------------------------------------- }

class function TCasScriptWhile.ShortName: String;
begin
  Result := 'while';
end;

class procedure TCasScriptWhile.HandleWhile(
  AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);

  function ExecuteCondition: Boolean;
  var
    Condition: TCasScriptValue;
  begin
    Condition := AFunction.Args[0].CoreExecute;
    if Condition is TCasScriptBoolean then
      Result := TCasScriptBoolean(Condition).Value else
      raise ECasScriptError.Create('"if" function "condition" must return a boolean value');
  end;

begin
  if ParentOfResult then
    AResult.FreeByParentExpression;
  AResult := nil;
  ParentOfResult := false;

  while ExecuteCondition do
    AResult := AFunction.Args[1].CoreExecute;

  if AResult = nil then
  begin
    { not executed even once? return const false }
    AResult := TCasScriptBoolean.Create(false);
    ParentOfResult := true;
  end;
end;

class function TCasScriptWhile.GreedyArgumentsCalculation: Integer;
begin
  Result := 0;
end;

{ TCasScriptFor --------------------------------------------------------- }

class function TCasScriptFor.ShortName: String;
begin
  Result := 'for';
end;

class procedure TCasScriptFor.HandleFor(
  AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
var
  BeginVal, EndVal: Int64;
  I: Integer;
begin
  if ParentOfResult then
    AResult.FreeByParentExpression;
  AResult := nil;
  ParentOfResult := false;

  BeginVal := TCasScriptInteger(Arguments[1]).Value;
  EndVal := TCasScriptInteger(Arguments[2]).Value;

  for I := BeginVal to EndVal do
  begin
    { We use Arguments[0] here, not AFunction.Args[0], this way
      we know we really have TCasScriptInteger here. While CheckArguments
      makes sure Args[0] is TCasScriptValue, it may be TCasScriptParameterValue.
      We know that TCasScriptParameterValue.Execute returns actual value,
      so Arguments[0] is Ok here. }
    (Arguments[0] as TCasScriptInteger).Value := I;

    AResult := AFunction.Args[3].CoreExecute;
  end;

  if AResult = nil then
  begin
    { not executed even once? return const false }
    AResult := TCasScriptBoolean.Create(false);
    ParentOfResult := true;
  end;
end;

class function TCasScriptFor.GreedyArgumentsCalculation: Integer;
begin
  Result := 3;
end;

class function TCasScriptFor.ArgumentMustBeAssignable(const Index: Integer): Boolean;
begin
  { This will cause checking whether Args[0] is assignable TCasScriptValue.

    Note that I cannot check in CheckArguments whether is
    Args[0] is TCasScriptInteger,
    as it may be TCasScriptParameterValue, and so the actual runtime type
    (TCasScriptParameterValue.SourceValue) may be not set yet.
    That's Ok, in HandleFor this will be automatically checked by AssignValue. }

  Result := Index = 0;
end;

{ TCasScriptCoalesce --------------------------------------------------------- }

class function TCasScriptCoalesce.ShortName: String;
begin
  Result := 'coalesce';
end;

class procedure TCasScriptCoalesce.HandleCoalesce(
  AFunction: TCasScriptFunction; const Arguments: array of TCasScriptValue; var AResult: TCasScriptValue; var ParentOfResult: Boolean);
var
  I: Integer;
begin
  if ParentOfResult then
    AResult.FreeByParentExpression;
  AResult := nil;
  ParentOfResult := false;

  for I := 0 to High(Arguments) - 1 do
  begin
    AResult := AFunction.Args[I].CoreExecute;
    if (AResult as TCasScriptString).Value <> '' then
      Exit;
    { Do not free it, it would cause SEGFAULT:
    AResult.FreeByParentExpression;
    AResult := nil;
    }
  end;

  AResult := AFunction.Args[High(Arguments)].CoreExecute;
end;

class function TCasScriptCoalesce.GreedyArgumentsCalculation: Integer;
begin
  Result := 0;
end;

{ TCasScriptFunctionHandlers ------------------------------------------------- }

constructor TCasScriptFunctionHandlers.Create;
begin
  inherited;
  FHandlersByFunction := Contnrs.TObjectList.Create(true);
end;

destructor TCasScriptFunctionHandlers.Destroy;
begin
  FreeAndNil(FHandlersByFunction);
  inherited;
end;

function TCasScriptFunctionHandlers.SearchFunctionClass(
  FunctionClass: TCasScriptFunctionClass;
  out FunctionIndex: Integer;
  out HandlersByArgument: Contnrs.TObjectList): Boolean;
var
  I: Integer;
begin
  for I := 0 to FHandlersByFunction.Count - 1 do
  begin
    HandlersByArgument := FHandlersByFunction[I] as Contnrs.TObjectList;
    if FunctionClass = (HandlersByArgument[0] as
      TCasScriptRegisteredHandler).FunctionClass then
    begin
      FunctionIndex := I;
      Result := true;
      Exit;
    end;
  end;
  Result := false;
end;

function TCasScriptFunctionHandlers.SearchFunctionClass(
  FunctionClass: TCasScriptFunctionClass;
  out HandlersByArgument: Contnrs.TObjectList): Boolean;
var
  FunctionIndex: Integer;
begin
  Result := SearchFunctionClass(
    FunctionClass, FunctionIndex, HandlersByArgument);
end;

function TCasScriptFunctionHandlers.SearchArgumentClasses(
  HandlersByArgument: Contnrs.TObjectList;
  const ArgumentClasses: TCasScriptValueClassArray;
  out ArgumentIndex: Integer;
  out Handler: TCasScriptRegisteredHandler): Boolean;
var
  I, J: Integer;
begin
  for I := 0 to HandlersByArgument.Count - 1 do
  begin
    Handler := HandlersByArgument[I] as TCasScriptRegisteredHandler;

    { First, check do we have enough arguments: at least
      Length(Handler.ArgumentClasses) are always required. }
    Result := Length(ArgumentClasses) >= Length(Handler.ArgumentClasses);

    if Result then
    begin
      for J := 0 to Length(ArgumentClasses) - 1 do
      begin
        Assert(Result);

        { Always accept ArgumentClasses[J] = nil, this means that they
          are "lazy" arguments (not calculated before handler actually executed),
          so they are simply always assumed Ok. }

        if ArgumentClasses[J] <> nil then
        begin
          if J < Length(Handler.ArgumentClasses) then
            Result := ArgumentClasses[J].InheritsFrom(Handler.ArgumentClasses[J]) else
            { This is more than required number of arguments.
              Still it's Ok if it matches last argument and function allows variable
              number of arguments. }
            Result := Handler.VariableArgumentsCount and
              (Length(Handler.ArgumentClasses) > 0) and
              ArgumentClasses[J].InheritsFrom(
                Handler.ArgumentClasses[High(Handler.ArgumentClasses)]);
        end;

        if not Result then Break;
      end;

      if Result then
      begin
        ArgumentIndex := I;
        Exit;
      end;
    end;
  end;
  Result := false;
end;

function TCasScriptFunctionHandlers.SearchArgumentClasses(
  HandlersByArgument: Contnrs.TObjectList;
  const ArgumentClasses: TCasScriptValueClassArray;
  out Handler: TCasScriptRegisteredHandler): Boolean;
var
  ArgumentIndex: Integer;
begin
  Result := SearchArgumentClasses(
    HandlersByArgument, ArgumentClasses, ArgumentIndex, Handler);
end;

function TCasScriptFunctionHandlers.SearchArgumentClasses(
  HandlersByArgument: Contnrs.TObjectList;
  const ArgumentClasses: TCasScriptValueClassArray;
  out Handler: TCasScriptRegisteredHandler;
  var Cache: TCasScriptSearchArgumentClassesCache): Boolean;

  function ArgumentClassesEqual(const A1, A2: TCasScriptValueClassArray): Boolean;
  begin
    Result := (Length(A1) = Length(A2)) and
      CompareMem(Pointer(A1), Pointer(A2), SizeOf(TCasScriptValueClass) * Length(A1));
  end;

begin
  if Cache.IsCache and
     (Cache.QueryHandlersByArgument = HandlersByArgument) and
     ArgumentClassesEqual(Cache.QueryArgumentClasses, ArgumentClasses) then
  begin
    { Use the cached result }
    Handler := Cache.AnswerHandler;
    { ArgumentIndex := Cache.ArgumentIndex; not returned here }
    Result := Cache.Answer;
  end else
  begin
    { Result not in the cache. So calculate it, and record in the cache. }
    Cache.IsCache := true;
    Cache.QueryHandlersByArgument := HandlersByArgument;
    { Copying the reference here, by
        Cache.QueryArgumentClasses := ArgumentClasses;
      would be incorrect: our argument may be a long-lived instance in
      TCasScriptFunction.ExecuteArgumentClasses, that is changed in
      TCasScriptFunction.CoreExecute. With a reference copy here,
      the CoreExecute would accidentaly change also our cache state,
      which will cause trouble later.

      Testcase: demo_models/castle_script/edit_texture.x3dv,
      key "e", would cause errors, because suddenly CoreExecute may decide
      that TCasScriptFloat.HandleAdd may be called without promoting int to float. }
    Cache.QueryArgumentClasses := Copy(ArgumentClasses, 0, Length(ArgumentClasses));
    Cache.Answer := SearchArgumentClasses(
      HandlersByArgument, ArgumentClasses,
      Cache.AnswerArgumentIndex, Cache.AnswerHandler);

    { Use the cached result }
    Handler := Cache.AnswerHandler;
    { ArgumentIndex := Cache.ArgumentIndex; not returned here }
    Result := Cache.Answer;
  end;
end;

procedure TCasScriptFunctionHandlers.RegisterHandler(
  AHandler: TCasScriptFunctionHandler;
  AFunctionClass: TCasScriptFunctionClass;
  const AArgumentClasses: array of TCasScriptValueClass;
  const AVariableArgumentsCount: Boolean);
var
  HandlersByArgument: Contnrs.TObjectList;
  Handler: TCasScriptRegisteredHandler;
  ArgumentClassesDyn: TCasScriptValueClassArray;
begin
  SetLength(ArgumentClassesDyn, High(AArgumentClasses) + 1);
  if Length(ArgumentClassesDyn) > 0 then
    Move(AArgumentClasses[0], ArgumentClassesDyn[0],
      SizeOf(TCasScriptValueClass) * Length(ArgumentClassesDyn));

  if SearchFunctionClass(AFunctionClass, HandlersByArgument) then
  begin
    if not SearchArgumentClasses(HandlersByArgument, ArgumentClassesDyn, Handler) then
    begin
      Handler := TCasScriptRegisteredHandler.Create(
        AHandler, AFunctionClass, ArgumentClassesDyn, AVariableArgumentsCount);
      HandlersByArgument.Add(Handler);
    end;
  end else
  begin
    HandlersByArgument := Contnrs.TObjectList.Create(true);
    FHandlersByFunction.Add(HandlersByArgument);

    Handler := TCasScriptRegisteredHandler.Create(
      AHandler, AFunctionClass, ArgumentClassesDyn, AVariableArgumentsCount);
    HandlersByArgument.Add(Handler);
  end;
end;

function TCasScriptFunctionHandlers.SearchFunctionShortName(
  const AShortName: String): TCasScriptFunctionClass;
var
  I: Integer;
  HandlersByArgument: Contnrs.TObjectList;
begin
  for I := 0 to FHandlersByFunction.Count - 1 do
  begin
    HandlersByArgument := FHandlersByFunction[I] as Contnrs.TObjectList;
    Result := (HandlersByArgument[0] as
      TCasScriptRegisteredHandler).FunctionClass;
    if SameText(AShortName, Result.ShortName) then
      Exit;
  end;
  Result := nil;
end;

{ TCasScriptUserFunction ----------------------------------------------- }

constructor TCasScriptUserFunction.Create;
begin
  inherited;
  FParameters := TCasScriptValueList.Create(true);
end;

destructor TCasScriptUserFunction.Destroy;
begin
  if Body <> nil then
    Body.FreeByParentExpression;
  FreeAndNil(FParameters);
  inherited;
end;

{ TCasScriptUserFunctionList ------------------------------------------ }

function TCasScriptUserFunctionList.IndexOfName(const FunctionName: String): Integer;
begin
  for Result := 0 to Count - 1 do
    if SameText(FunctionName, Items[Result].Name) then
      Exit;
  Result := -1;
end;

{ TCasScriptProgram ---------------------------------------------------------- }

constructor TCasScriptProgram.Create;
begin
  inherited;
  FFunctions := TCasScriptUserFunctionList.Create(true);
  FEnvironment := TCasScriptEnvironment.Create;
end;

destructor TCasScriptProgram.Destroy;
begin
  FreeAndNil(FFunctions);
  FreeAndNil(FEnvironment);
  inherited;
end;

procedure TCasScriptProgram.ExecuteFunction(const FunctionName: String;
  const Parameters: array of TCasScriptValue;
  const IgnoreMissingFunction: Boolean);
var
  Func: TCasScriptUserFunction;
  FuncIndex, I: Integer;
begin
  FuncIndex := Functions.IndexOfName(FunctionName);
  if FuncIndex = -1 then
  begin
    if IgnoreMissingFunction then
      Exit else
      raise ECasScriptMissingFunction.CreateFmt('CastleScript function "%s" is not defined', [FunctionName]);
  end;
  Func := Functions[FuncIndex];

  if High(Parameters) <> Func.Parameters.Count - 1 then
    raise ECasScriptError.CreateFmt('CastleScript function "%s" requires %d parameters, but passed %d parameters',
      [FunctionName, Func.Parameters.Count, High(Parameters) + 1]);

  for I := 0 to High(Parameters) do
    (Func.Parameters[I] as TCasScriptParameterValue).SourceValue := Parameters[I];

  Func.Body.Execute;

  { Just for safety, clear SourceValue references.

    This is safe, since no code can access Parameters instances
    (trying to get their value directly or by AssignValue) after
    ExecuteFunction. Code from the outside can only access it's own
    global variables after execution, which have values directly stored.

    This *could* become a problem if we want to return function's value
    in the future, then this will possibly have to be removed,
    as Func.Body.Execute may directly return one of our Parameters. }

  for I := 0 to High(Parameters) do
    (Func.Parameters[I] as TCasScriptParameterValue).SourceValue := nil;
end;

{ procedural utils ----------------------------------------------------------- }

procedure CreateValueIfNeeded(var Value: TCasScriptValue;
  var ParentOfValue: Boolean;
  NeededClass: TCasScriptValueClass);
begin
  if Value = nil then
  begin
    Value := NeededClass.Create(false);
    ParentOfValue := true;
  end else
  if Value.ClassType <> NeededClass then
  begin
    if ParentOfValue then
      Value.FreeByParentExpression else
      Value := nil;

    Value := NeededClass.Create(false);
    ParentOfValue := true;
  end;
end;

{ unit init/fini ------------------------------------------------------------- }

var
  FFunctionHandlers: TCasScriptFunctionHandlers;

function FunctionHandlers: TCasScriptFunctionHandlers;
begin
  { Create on-demand, just in case CastleScriptVectors initialization
    is executed earlier than CastleScript initialization. }
  if FFunctionHandlers = nil then
    FFunctionHandlers := TCasScriptFunctionHandlers.Create;
  Result := FFunctionHandlers;
end;

initialization
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptSequence(nil).HandleSequence, TCasScriptSequence, [TCasScriptValue], true);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptAssignment(nil).HandleAssignment, TCasScriptAssignment, [TCasScriptValue, TCasScriptValue], false);

  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptIf(nil).HandleIf, TCasScriptIf, [TCasScriptBoolean, TCasScriptValue, TCasScriptValue], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptWhen(nil).HandleWhen, TCasScriptWhen, [TCasScriptBoolean, TCasScriptValue], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptWhile(nil).HandleWhile, TCasScriptWhile, [TCasScriptBoolean, TCasScriptValue], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFor(nil).HandleFor, TCasScriptFor, [TCasScriptInteger, TCasScriptInteger, TCasScriptInteger, TCasScriptValue], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptCoalesce(nil).HandleCoalesce, TCasScriptCoalesce, [TCasScriptString], true);

  { Register handlers for TCasScriptInteger for functions in
    CastleScriptCoreFunctions. }
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptInteger(nil).HandleAdd, TCasScriptAdd, [TCasScriptInteger], true);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptInteger(nil).HandleSubtract, TCasScriptSubtract, [TCasScriptInteger], true);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptInteger(nil).HandleNegate, TCasScriptNegate, [TCasScriptInteger], false);

  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptInteger(nil).HandleMultiply, TCasScriptMultiply, [TCasScriptInteger], true);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptInteger(nil).HandleDivide, TCasScriptDivide, [TCasScriptInteger], true);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptInteger(nil).HandleModulo, TCasScriptModulo, [TCasScriptInteger, TCasScriptInteger], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptInteger(nil).HandlePower, TCasScriptPower, [TCasScriptInteger, TCasScriptInteger], false);

  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptInteger(nil).HandleMax, TCasScriptMax, [TCasScriptInteger], true);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptInteger(nil).HandleMin, TCasScriptMin, [TCasScriptInteger], true);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptInteger(nil).HandleSqr, TCasScriptSqr, [TCasScriptInteger], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptInteger(nil).HandleSgn, TCasScriptSgn, [TCasScriptInteger], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptInteger(nil).HandleAbs, TCasScriptAbs, [TCasScriptInteger], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptInteger(nil).HandleRandom, TCasScriptRandom, [TCasScriptInteger], false);

  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptInteger(nil).HandleGreater, TCasScriptGreater, [TCasScriptInteger, TCasScriptInteger], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptInteger(nil).HandleLesser, TCasScriptLesser, [TCasScriptInteger, TCasScriptInteger], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptInteger(nil).HandleGreaterEq, TCasScriptGreaterEq, [TCasScriptInteger, TCasScriptInteger], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptInteger(nil).HandleLesserEq, TCasScriptLesserEq, [TCasScriptInteger, TCasScriptInteger], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptInteger(nil).HandleEqual, TCasScriptEqual, [TCasScriptInteger, TCasScriptInteger], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptInteger(nil).HandleNotEqual, TCasScriptNotEqual, [TCasScriptInteger, TCasScriptInteger], false);

  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptInteger(nil).ConvertFromInt   , TCasScriptInt, [TCasScriptInteger], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptInteger(nil).ConvertFromFloat , TCasScriptInt, [TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptInteger(nil).ConvertFromBool  , TCasScriptInt, [TCasScriptBoolean], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptInteger(nil).ConvertFromString, TCasScriptInt, [TCasScriptString], false);

  { Register handlers for TCasScriptFloat for functions in
    CastleScriptCoreFunctions. }
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleAdd, TCasScriptAdd, [TCasScriptFloat], true);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleSubtract, TCasScriptSubtract, [TCasScriptFloat], true);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleMultiply, TCasScriptMultiply, [TCasScriptFloat], true);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleDivide, TCasScriptDivide, [TCasScriptFloat], true);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleLerp, TCasScriptLerp, [TCasScriptFloat, TCasScriptFloat, TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleNegate, TCasScriptNegate, [TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleModulo, TCasScriptModulo, [TCasScriptFloat, TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleSin, TCasScriptSin, [TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleCos, TCasScriptCos, [TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleTan, TCasScriptTan, [TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleCotan, TCasScriptCotan, [TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleArcSin, TCasScriptArcSin, [TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleArcCos, TCasScriptArcCos, [TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleArcTan, TCasScriptArcTan, [TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleArcCotan, TCasScriptArcCotan, [TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleSinh, TCasScriptSinh, [TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleCosh, TCasScriptCosh, [TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleTanh, TCasScriptTanh, [TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleCotanh, TCasScriptCotanh, [TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleLog2, TCasScriptLog2, [TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleLn, TCasScriptLn, [TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleLog, TCasScriptLog, [TCasScriptFloat, TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandlePower2, TCasScriptPower2, [TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleExp, TCasScriptExp, [TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandlePower, TCasScriptPower, [TCasScriptFloat, TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleSqr, TCasScriptSqr, [TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleSqrt, TCasScriptSqrt, [TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleMax, TCasScriptMax, [TCasScriptFloat], true);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleMin, TCasScriptMin, [TCasScriptFloat], true);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleSgn, TCasScriptSgn, [TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleAbs, TCasScriptAbs, [TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleRandom, TCasScriptRandom, [], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleCeil, TCasScriptCeil, [TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleFloor, TCasScriptFloor, [TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleRound, TCasScriptRound, [TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleGreater, TCasScriptGreater, [TCasScriptFloat, TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleLesser, TCasScriptLesser, [TCasScriptFloat, TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleGreaterEq, TCasScriptGreaterEq, [TCasScriptFloat, TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleLesserEq, TCasScriptLesserEq, [TCasScriptFloat, TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleEqual, TCasScriptEqual, [TCasScriptFloat, TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).HandleNotEqual, TCasScriptNotEqual, [TCasScriptFloat, TCasScriptFloat], false);

  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).ConvertFromInt   , TCasScriptFloatFun, [TCasScriptInteger], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).ConvertFromFloat , TCasScriptFloatFun, [TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).ConvertFromBool  , TCasScriptFloatFun, [TCasScriptBoolean], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptFloat(nil).ConvertFromString, TCasScriptFloatFun, [TCasScriptString], false);

  { Register handlers for TCasScriptBoolean for functions in
    CastleScriptCoreFunctions. }
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptBoolean(nil).HandleOr, TCasScriptOr, [TCasScriptBoolean], true);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptBoolean(nil).HandleAnd, TCasScriptAnd, [TCasScriptBoolean], true);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptBoolean(nil).HandleNot, TCasScriptNot, [TCasScriptBoolean], false);

  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptBoolean(nil).HandleGreater, TCasScriptGreater, [TCasScriptBoolean, TCasScriptBoolean], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptBoolean(nil).HandleLesser, TCasScriptLesser, [TCasScriptBoolean, TCasScriptBoolean], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptBoolean(nil).HandleGreaterEq, TCasScriptGreaterEq, [TCasScriptBoolean, TCasScriptBoolean], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptBoolean(nil).HandleLesserEq, TCasScriptLesserEq, [TCasScriptBoolean, TCasScriptBoolean], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptBoolean(nil).HandleEqual, TCasScriptEqual, [TCasScriptBoolean, TCasScriptBoolean], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptBoolean(nil).HandleNotEqual, TCasScriptNotEqual, [TCasScriptBoolean, TCasScriptBoolean], false);

  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptBoolean(nil).ConvertFromInt   , TCasScriptBool, [TCasScriptInteger], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptBoolean(nil).ConvertFromFloat , TCasScriptBool, [TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptBoolean(nil).ConvertFromBool  , TCasScriptBool, [TCasScriptBoolean], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptBoolean(nil).ConvertFromString, TCasScriptBool, [TCasScriptString], false);

  { Register handlers for TCasScriptString for functions in
    CastleScriptCoreFunctions. }
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptString(nil).HandleAdd, TCasScriptAdd, [TCasScriptString, TCasScriptString], false);

  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptString(nil).HandleGreater, TCasScriptGreater, [TCasScriptString, TCasScriptString], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptString(nil).HandleLesser, TCasScriptLesser, [TCasScriptString, TCasScriptString], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptString(nil).HandleGreaterEq, TCasScriptGreaterEq, [TCasScriptString, TCasScriptString], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptString(nil).HandleLesserEq, TCasScriptLesserEq, [TCasScriptString, TCasScriptString], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptString(nil).HandleEqual, TCasScriptEqual, [TCasScriptString, TCasScriptString], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptString(nil).HandleNotEqual, TCasScriptNotEqual, [TCasScriptString, TCasScriptString], false);

  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptString(nil).ConvertFromInt   , TCasScriptStringFun, [TCasScriptInteger], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptString(nil).ConvertFromFloat , TCasScriptStringFun, [TCasScriptFloat], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptString(nil).ConvertFromBool  , TCasScriptStringFun, [TCasScriptBoolean], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptString(nil).ConvertFromString, TCasScriptStringFun, [TCasScriptString], false);

  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptString(nil).HandleWriteln, TCasScriptWriteln, [TCasScriptString], false);
  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptString(nil).HandleCharacterFromCode, TCasScriptCharacterFromCode, [TCasScriptInteger], false);

  FunctionHandlers.RegisterHandler({$ifdef CASTLE_OBJFPC}@{$endif} TCasScriptShortcut(nil).Handle, TCasScriptShortcut, [TCasScriptString], false);
finalization
  FreeAndNil(FFunctionHandlers);
end.
