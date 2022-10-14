unit Citrus.Lime;

interface

uses
  Citrus.Types,
  System.JSON,
  System.JSON.Serializers,
  System.Rtti,
  System.SysUtils,
  System.Generics.Collections;

type
  LimeUrlAttribute = class(TCustomAttribute)
  private
    FUrl: string;
    FMethod: string;
  public
    constructor Create(const AMethod, AUrl: string);
    property Url: string read FUrl write FUrl;
    property Method: string read FMethod write FMethod;
  end;

  LimeParameterAttribute = class(TCustomAttribute)
  private
    FType: TCitrusParameterType;
  public
    constructor Create(const AType: TCitrusParameterType);
    property &Type: TCitrusParameterType read FType write FType;
  end;

  TLime = class
  private
    FRttiCtx: TRttiContext;
    FSerializer: TJsonSerializer;
    FOnSerialize: TProc<string>;
    FOnUrl: TProc<string, string>;
    FVariables: TDictionary<string, string>;
    FOnParameter: TProc<string, string, TCitrusParameterType>;
  protected
    procedure ReplaceVariables(var AInput: string);
    procedure ScanField(ARttiField: TRttiField; AJson: TJSONValue);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Scan<T>(AArgument: T);
    property Serializer: TJsonSerializer read FSerializer write FSerializer;
    property OnSerialize: TProc<string> read FOnSerialize write FOnSerialize;
    property OnUrl: TProc<string, string> read FOnUrl write FOnUrl;
    property OnParameter: TProc<string, string, TCitrusParameterType> read FOnParameter write FOnParameter;
    property Variables: TDictionary<string, string> read FVariables;
  end;

implementation

uses
  System.JSON.Types;

{ TLime }

constructor TLime.Create;
begin
  inherited;
  FSerializer := TJsonSerializer.Create();
  FSerializer.Formatting := TJsonFormatting.Indented;
  FRttiCtx := TRttiContext.Create();
  FVariables := TDictionary<string, string>.Create();
end;

destructor TLime.Destroy;
begin
  FVariables.Free;
  FRttiCtx.Free;
  FSerializer.Free;
  inherited Destroy;
end;

procedure TLime.ReplaceVariables(var AInput: string);
var
  LVar: TPair<string, string>;
begin
  for LVar in FVariables do
    AInput := AInput.Replace('{' + LVar.Key + '}', LVar.Value);
end;

procedure TLime.Scan<T>(AArgument: T);
var
  LArgumentAsJsonString: string;
  LJsonObj: TJSONValue;
  LRttiType: TRttiType;
  LRttiField: TRttiField;
  LAttr: TCustomAttribute;
  LUrl: string;
begin
  LArgumentAsJsonString := FSerializer.Serialize<T>(AArgument);
  if Assigned(OnSerialize) then
    OnSerialize(LArgumentAsJsonString);
  LJsonObj := TJSONObject.ParseJSONValue(LArgumentAsJsonString) as TJSONValue;
  try
    LRttiType := FRttiCtx.GetType(TypeInfo(T));
    try
      for LAttr in LRttiType.GetAttributes do
      begin
        if LAttr is LimeParameterAttribute then
        begin
          if Assigned(OnParameter) then
            OnParameter('', LJsonObj.ToJSON, (LAttr as LimeParameterAttribute).&Type);
        end;
        if LAttr is LimeUrlAttribute then
        begin
          if Assigned(OnUrl) then
          begin
            LUrl := (LAttr as LimeUrlAttribute).Url;
            ReplaceVariables(LUrl);
            OnUrl((LAttr as LimeUrlAttribute).Method, LUrl);
          end;
        end;
      end;
      for LRttiField in LRttiType.GetFields do
      begin
        ScanField(LRttiField, LJsonObj);
      end;
    finally
      LRttiType.Free;
    end;
  finally
    LJsonObj.Free;
  end;
end;

procedure TLime.ScanField(ARttiField: TRttiField; AJson: TJSONValue);
var
  LAttr: TCustomAttribute;
  //
  LName: string;
  LValue: string;
  LParameterType: TCitrusParameterType;
  LCallEvent: Boolean;
begin
  LCallEvent := False;
  LName := ARttiField.Name;
  LParameterType := TCitrusParameterType.GetOrPost;
  for LAttr in ARttiField.GetAttributes do
  begin
    if LAttr is JsonNameAttribute then
      LName := (LAttr as JsonNameAttribute).Value;
    if LAttr is LimeParameterAttribute then
    begin
      LParameterType := (LAttr as LimeParameterAttribute).&Type;
      LCallEvent := True;
    end;
  end;
  LValue := AJson.P[LName].Value();
  if Assigned(OnParameter) and LCallEvent then
    OnParameter(LName, LValue, LParameterType);
end;

constructor LimeUrlAttribute.Create(const AMethod, AUrl: string);
begin
  inherited Create;
  FUrl := AUrl;
  FMethod := AMethod;
end;

constructor LimeParameterAttribute.Create(const AType: TCitrusParameterType);
begin
  inherited Create;
  FType := AType;
end;

end.
