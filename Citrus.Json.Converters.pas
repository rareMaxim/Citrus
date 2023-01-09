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
  x: TJsonReaderToValue;
  res: TJSONObject;
  xx: string;
begin
  x := TJsonReaderToValue.Create;
  try
    res := TJSONObject.Create;
    x.Parse(AReader, res);
    xx := res.ToJSON;
    Writeln(xx);
  finally
    x.Free;
  end;
end;

procedure TJsonToJsonObjectConverter.WriteJson(const AWriter: TJsonWriter; const AValue: TValue;
  const ASerializer: TJsonSerializer);
begin
  inherited;

end;

{ TJsonReaderToValue }

class procedure TJsonReaderToValue.Parse(AReader: TJsonReader; var AJObj: TJSONObject);
var
  lPropertyName: string;
begin
  while AReader.Read do
  begin
    Writeln(Format('[%d %d]: %s', [AReader.LineNumber, AReader.GetLinePosition, AReader.Path]));
    case AReader.TokenType of
      TJsonToken.None:
        ;
      TJsonToken.StartObject:
        begin
          var
          LJObj := AJObj.AddPair(lPropertyName, TJSONObject.Create as TJSONValue);
          Parse(AReader, LJObj);
        end;
      TJsonToken.StartArray:
        begin
          var
          LJObj := AJObj.AddPair(lPropertyName, TJSONArray.Create as TJSONValue);
          Parse(AReader, LJObj);
        end;
      TJsonToken.StartConstructor:
        ;
      TJsonToken.PropertyName:
        begin
          lPropertyName := AReader.Value.ToString;

        end;
      TJsonToken.Comment:
        ;
      TJsonToken.Raw:
        ;
      TJsonToken.Integer:
        ;
      TJsonToken.Float:
        ;
      TJsonToken.String:
        begin
          AJObj.AddPair(lPropertyName, TJSONString.Create(AReader.Value.AsType<string>));
        end;
      TJsonToken.Boolean:
        ;
      TJsonToken.Null:
        ;
      TJsonToken.Undefined:
        ;
      TJsonToken.EndObject:
        Exit;
      TJsonToken.EndArray:
        ;
      TJsonToken.EndConstructor:
        ;
      TJsonToken.Date:
        ;
      TJsonToken.Bytes:
        ;
      TJsonToken.Oid:
        ;
      TJsonToken.RegEx:
        ;
      TJsonToken.DBRef:
        ;
      TJsonToken.CodeWScope:
        ;
      TJsonToken.MinKey:
        ;
      TJsonToken.MaxKey:
        ;
    end;
  end;
end;

end.
