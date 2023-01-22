unit Citrus.Json.Converters;

interface

uses
  System.Json,
  System.Json.Readers,
  System.Json.Serializers,
  System.Json.Writers,
  System.Json.Converters,
  System.Rtti,
  System.TypInfo, System.SysUtils;

type
  // --------------------------------------------------------------------- //
  // Converter for UnixTime
  // --------------------------------------------------------------------- //
  TJsonUnixTimeConverter = class(TJsonConverter)
  public
    procedure WriteJson(const AWriter: TJsonWriter; const AValue: TValue; const ASerializer: TJsonSerializer); override;
    function ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo; const AExistingValue: TValue;
      const ASerializer: TJsonSerializer): TValue; override;
    function CanConvert(ATypeInf: PTypeInfo): Boolean; override;
  end;

  TJsonToJsonObjectConverter = class(TJsonConverter)
  public
    procedure WriteJson(const AWriter: TJsonWriter; const AValue: TValue; const ASerializer: TJsonSerializer); override;
    function ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo; const AExistingValue: TValue;
      const ASerializer: TJsonSerializer): TValue; override;
    function CanConvert(ATypeInf: PTypeInfo): Boolean; override;
  end;

  TJsonReaderToValue = class
  public
    class procedure Parse(AReader: TJsonReader; var AJObj: TJSONObject);
  end;

implementation

uses
  System.DateUtils, System.Json.Types;

{ TJsonUnixTimeConverter }

function TJsonUnixTimeConverter.CanConvert(ATypeInf: PTypeInfo): Boolean;
begin
  Result := ATypeInf^.Kind = tkInt64;
end;

function TJsonUnixTimeConverter.ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo; const AExistingValue: TValue;
  const ASerializer: TJsonSerializer): TValue;
var
  LRawInt: Int64;
  LDateTime: TDateTime;
begin
  LRawInt := AReader.Value.AsInt64;
  LDateTime := UnixToDateTime(LRawInt, False);
  TValue.Make(@LDateTime, ATypeInf, Result);
end;

procedure TJsonUnixTimeConverter.WriteJson(const AWriter: TJsonWriter; const AValue: TValue;
  const ASerializer: TJsonSerializer);
begin
  AWriter.WriteValue(DateTimeToUnix(AValue.AsType<TDateTime>(), True));
end;

{ TJsonToJsonObjectConverter }

function TJsonToJsonObjectConverter.CanConvert(ATypeInf: PTypeInfo): Boolean;
begin
  Result := ATypeInf.Name = TJSONObject.ClassName;
end;

function TJsonToJsonObjectConverter.ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo;
  const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue;
var
  List: TJSONObject;
begin
  if AReader.TokenType = TJsonToken.Null then
    Result := nil
  else
  begin
    if AExistingValue.IsEmpty then
      List := TJSONObject.Create
    else
      List := AExistingValue.AsType<TJSONObject>;
    TJsonReaderToValue.Parse(AReader, List);
    Result := TValue.From(List);
  end;
end;

procedure TJsonToJsonObjectConverter.WriteJson(const AWriter: TJsonWriter; const AValue: TValue;
  const ASerializer: TJsonSerializer);
begin
  AWriter.WriteValue(AValue.AsType<TJSONObject>.ToJSON);
end;

{ TJsonReaderToValue }

class procedure TJsonReaderToValue.Parse(AReader: TJsonReader; var AJObj: TJSONObject);
var
  lPropertyName: string;
  LJsonObject: TJSONObject;
begin
  while AReader.Read do
  begin
    case AReader.TokenType of
      TJsonToken.StartObject:
        begin
          LJsonObject := AJObj.AddPair(lPropertyName, TJSONObject.Create as TJSONValue);
          Parse(AReader, LJsonObject);
        end;
      TJsonToken.StartArray:
        begin
          LJsonObject := AJObj.AddPair(lPropertyName, TJSONArray.Create as TJSONValue);
          Parse(AReader, LJsonObject);
        end;
      TJsonToken.PropertyName:
        lPropertyName := AReader.Value.ToString;
      TJsonToken.String:
        AJObj.AddPair(lPropertyName, TJSONString.Create(AReader.Value.AsType<string>));
      TJsonToken.Boolean:
        AJObj.AddPair(lPropertyName, TJSONBool.Create(AReader.Value.AsType<Boolean>));
      TJsonToken.Integer:
        AJObj.AddPair(lPropertyName, TJSONNumber.Create(AReader.Value.AsType<Integer>));
      TJsonToken.Null:
        AJObj.AddPair(lPropertyName, TJSONNull.Create());
      TJsonToken.EndObject, TJsonToken.EndArray:
        Exit;
    else
      raise EJsonException.CreateFmt('[%d %d %s]: %s', [AReader.LineNumber, AReader.LinePosition,
        TRttiEnumerationType.GetName<TJsonToken>(AReader.TokenType), AReader.Path]);
    end;
  end;
end;

end.
