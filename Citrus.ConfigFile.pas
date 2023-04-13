unit Citrus.ConfigFile;

interface

uses
  System.Json.Serializers;

type
  TConfigFile = class
  private
    [JsonIgnore]
    FFileName: string;
    function DoReadFile(const AFileName: string): string;
    procedure DoSaveFile(const AFileName, AData: string);
    procedure DoPopulate(const AData: string);
    function DoSerialize: string;
    procedure BuildConfig;
    procedure SaveConfig;
  public
    constructor Create(const AFileName: string);
    destructor Destroy; override;

  end;

implementation

uses
  Citrus.JObject,
  System.IOUtils,
  System.SysUtils;

procedure TConfigFile.BuildConfig;
var
  LData: string;
begin
  if FileExists(FFileName) then
  begin
    LData := DoReadFile(FFileName);
    DoPopulate(LData);
  end;
end;

constructor TConfigFile.Create(const AFileName: string);
begin
  inherited Create;
  FFileName := AFileName;
  BuildConfig;
end;

destructor TConfigFile.Destroy;
begin
  SaveConfig;
  inherited;
end;

procedure TConfigFile.DoPopulate(const AData: string);
begin
  TJObjectConfig.Current.Serializer.Populate<TConfigFile>(AData, Self);
end;

function TConfigFile.DoReadFile(const AFileName: string): string;
begin
  Result := TFile.ReadAllText(AFileName, TEncoding.UTF8);
end;

procedure TConfigFile.DoSaveFile(const AFileName, AData: string);
begin
  TFile.WriteAllText(AFileName, AData);
end;

function TConfigFile.DoSerialize: string;
begin
  Result := TJObjectConfig.Current.Serializer.Serialize<TConfigFile>(Self);
end;

procedure TConfigFile.SaveConfig;
var
  LData: string;
begin
  LData := DoSerialize;
  DoSaveFile(FFileName, LData);
end;

end.
