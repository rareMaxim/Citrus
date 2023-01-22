unit Citrus.JObject;

interface

uses
  System.JSON,
  System.JSON.Serializers,
  Citrus.JSON.Converters,
  System.TypInfo,
  System.JSON.Writers,
  System.JSON.Readers,
  System.Rtti;

type
  TJObjectConverter = class(TJsonToJsonObjectConverter)
  public
    procedure WriteJson(const AWriter: TJsonWriter; const AValue: TValue; const ASerializer: TJsonSerializer); override;
    function ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo; const AExistingValue: TValue;
      const ASerializer: TJsonSerializer): TValue; override;
    function CanConvert(ATypeInf: PTypeInfo): Boolean; override;
  end;

  TJObject = class
  private
    FJsonObject: TJSONObject;
  public
    constructor Create;
    destructor Destroy; override;
    function ToObject<T>: T;
  end;

  TJObjectConfig = class
  private
    class var FCurrent: TJObjectConfig;
  private
    FSerializer: TJsonSerializer;
  protected
    class constructor Create;
    class destructor Destroy;
  public
    property Serializer: TJsonSerializer read FSerializer write FSerializer;
    constructor Create;
    destructor Destroy; override;
    class property Current: TJObjectConfig read FCurrent;
  end;

implementation

uses
  System.JSON.Types;

constructor TJObject.Create;
begin
  inherited Create;
  FJsonObject := TJSONObject.Create();
end;

destructor TJObject.Destroy;
begin
  FJsonObject.Free;
  inherited Destroy;
end;

{ TJObject }

function TJObject.ToObject<T>: T;
begin
  Result := TJObjectConfig.Current.Serializer.Deserialize<T>(FJsonObject.ToJSON);
end;

{ TJObjectConfig }

class constructor TJObjectConfig.Create;
begin
  FCurrent := TJObjectConfig.Create;
end;

constructor TJObjectConfig.Create;
begin
  inherited Create;
  FSerializer := TJsonSerializer.Create();
end;

class destructor TJObjectConfig.Destroy;
begin
  FCurrent.Free;
end;

destructor TJObjectConfig.Destroy;
begin
  FSerializer.Free;
  inherited Destroy;
end;

{ TJObjectConverter }

function TJObjectConverter.CanConvert(ATypeInf: PTypeInfo): Boolean;
begin
  Result := ATypeInf.Name = TJObject.ClassName;
end;

function TJObjectConverter.ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo; const AExistingValue: TValue;
  const ASerializer: TJsonSerializer): TValue;
var
  JObject: TJObject;
begin
  if AReader.TokenType = TJsonToken.Null then
    Result := nil
  else
  begin
    if AExistingValue.IsEmpty then
      JObject := TJObject.Create
    else
      JObject := AExistingValue.AsType<TJObject>;
    TJsonReaderToValue.Parse(AReader, JObject.FJsonObject);
    Result := TValue.From(JObject);
  end;
end;

procedure TJObjectConverter.WriteJson(const AWriter: TJsonWriter; const AValue: TValue;
  const ASerializer: TJsonSerializer);
begin
  AWriter.WriteValue(AValue.AsType<TJObject>.FJsonObject.ToJSON);
end;

end.
