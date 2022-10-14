unit Citrus.Json.Converters;

interface

uses
  System.Json.Readers,
  System.Json.Serializers,
  System.Json.Writers,
  System.Rtti,
  System.TypInfo;

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

implementation

uses
  System.DateUtils;

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

end.
