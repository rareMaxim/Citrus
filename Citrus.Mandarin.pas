unit Citrus.Mandarin;

interface

uses
  System.Generics.Collections,
  System.Net.HttpClient,
  System.Net.URLClient,
  System.Classes,
  System.JSON,
  System.JSON.Serializers,
  System.SysUtils;

type
{$SCOPEDENUMS ON}
  TMandarinBodyType = (None, Raw);
{$SCOPEDENUMS OFF}
  IHTTPResponse = System.Net.HttpClient.IHTTPResponse;

  TMandarinBody = class
  private
    FRaw: string;
    FType: TMandarinBodyType;
    FJson: TJSONObject;
    procedure SetRaw(const Value: string);
  protected
    procedure UpgradeHttpRequest(var ARequest: IHTTPRequest);
    procedure BuildRaw(var ARequest: IHTTPRequest);
  public
    constructor Create;
    property Raw: string read FRaw write SetRaw;
    property &Type: TMandarinBodyType read FType write FType;
    property JSON: TJSONObject read FJson;
  end;

  IMandarin = interface
    ['{41E70BCE-82B2-4937-87A7-C1F8A3F07FAB}']
    function BuildRequest(AHttpCli: THttpClient): IHTTPRequest;
    function GetRequestMethod: string;
    function GetUrl: string;
    procedure SetRequestMethod(const Value: string);
    procedure SetUrl(const Value: string);
    function GetBody: TMandarinBody;
    //
    function AddHeader(const AName, AValue: string): IMandarin;
    function AddQueryParameter(const AName, AValue: string): IMandarin;
    function AddUrlSegment(const AName, AValue: string): IMandarin;

    property RequestMethod: string read GetRequestMethod write SetRequestMethod;
    property Url: string read GetUrl write SetUrl;
    property Body: TMandarinBody read GetBody;
  end;

  TMandarin = class(TInterfacedObject, IMandarin)
  private
    FHeaders: TDictionary<string, string>;
    FUrlSegments: TDictionary<string, string>;
    FQueryParameters: TDictionary<string, string>;
    FUrl: string;
    FRequestMethod: string;
    FBody: TMandarinBody;
    function GetBody: TMandarinBody;
    function GetRequestMethod: string;
    function GetUrl: string;
    procedure SetRequestMethod(const Value: string);
    procedure SetUrl(const Value: string);
  protected
    procedure SetupHeaders(ARequest: IHTTPRequest);
    procedure SetupUrlSegments(var AUrl: string);
    procedure SetupQueryParameters(var AUrl: string);
    function BuildRequest(AHttpCli: THttpClient): IHTTPRequest;
  public
    constructor Create(const AUrl: string); overload;
    constructor Create; overload;
    destructor Destroy; override;
    function AddHeader(const AName, AValue: string): IMandarin;
    function AddQueryParameter(const AName, AValue: string): IMandarin;
    function AddUrlSegment(const AName, AValue: string): IMandarin;

    property Url: string read GetUrl write SetUrl;
    property Headers: TDictionary<string, string> read FHeaders;
    property UrlSegments: TDictionary<string, string> read FUrlSegments;
    property QueryParameters: TDictionary<string, string> read FQueryParameters;
    property RequestMethod: string read GetRequestMethod write SetRequestMethod;
    property Body: TMandarinBody read GetBody;
  end;

  IMandarinExt = interface(IMandarin)
    ['{0668D619-DEC1-4713-AEFF-A89F0BB67CC1}']
    procedure Execute(AResponseCallback: TProc<IHTTPResponse>; AIsSync: Boolean = True);
    procedure ExecuteSync(AResponseCallback: TProc<IHTTPResponse>);
    procedure ExecuteAsync(AResponseCallback: TProc<IHTTPResponse>);
    //
    function AddHeader(const AName, AValue: string): IMandarinExt;
    function AddQueryParameter(const AName, AValue: string): IMandarinExt;
    function AddUrlSegment(const AName, AValue: string): IMandarinExt;
  end;

  TMandarinClient = class;

  TMandarinExt = class(TMandarin, IMandarinExt)
  private
    FClient: TMandarinClient;
  public
    procedure Execute(AResponseCallback: TProc<IHTTPResponse>; AIsSync: Boolean = True);
    procedure ExecuteSync(AResponseCallback: TProc<IHTTPResponse>);
    procedure ExecuteAsync(AResponseCallback: TProc<IHTTPResponse>);
    constructor Create(AClient: TMandarinClient; const ABaseUrl: string = '');
    //
    function AddHeader(const AName, AValue: string): IMandarinExt;
    function AddQueryParameter(const AName, AValue: string): IMandarinExt;
    function AddUrlSegment(const AName, AValue: string): IMandarinExt;
  end;

  TMandarinClient = class
  private
    FHttp: THttpClient;
    FOnBeforeExcecute: TProc<IMandarin>;
  public
    procedure Execute(AMandarin: IMandarin; AResponseCallback: TProc<IHTTPResponse>;
      const AIsSyncMode: Boolean = True); virtual;
    procedure ExecuteSync(AMandarin: IMandarin; AResponseCallback: TProc<IHTTPResponse>); virtual;
    procedure ExecuteAsync(AMandarin: IMandarin; AResponseCallback: TProc<IHTTPResponse>); virtual;
    function NewMandarin(const ABaseUrl: string = ''): IMandarinExt;
    constructor Create; virtual;
    destructor Destroy; override;
    property Http: THttpClient read FHttp write FHttp;
    property OnBeforeExcecute: TProc<IMandarin> read FOnBeforeExcecute write FOnBeforeExcecute;
  end;

  IMandarinExtJson<T> = interface(IMandarin)
    ['{0668D619-DEC1-4713-AEFF-A89F0BB67CC1}']
    procedure Execute(AResponseCallback: TProc<T, IHTTPResponse>; const AIsSyncMode: Boolean = True);
    procedure ExecuteSync(AMandarin: IMandarin; AResponseCallback: TProc<T, IHTTPResponse>);
    procedure ExecuteAsync(AResponseCallback: TProc<T, IHTTPResponse>);
    //
    function AddHeader(const AName, AValue: string): IMandarinExtJson<T>;
    function AddQueryParameter(const AName, AValue: string): IMandarinExtJson<T>;
    function AddUrlSegment(const AName, AValue: string): IMandarinExtJson<T>;
    function AddJsonPair(const AName, AValue: string): IMandarinExtJson<T>;
    function SetBodyRaw(const AValue: string): IMandarinExtJson<T>;
    function SetRequestMethod(const AValue: string): IMandarinExtJson<T>;
  end;

  TMandarinClientJson = class;

  TMandarinExtJson<T> = class(TMandarin, IMandarinExtJson<T>)
  private
    FClient: TMandarinClientJson;
  public
    procedure Execute(AResponseCallback: TProc<T, IHTTPResponse>; const AIsSyncMode: Boolean = True);
    procedure ExecuteSync(AMandarin: IMandarin; AResponseCallback: TProc<T, IHTTPResponse>);
    procedure ExecuteAsync(AResponseCallback: TProc<T, IHTTPResponse>);
    constructor Create(AClient: TMandarinClientJson; const ABaseUrl: string = '');
    //
    function AddHeader(const AName, AValue: string): IMandarinExtJson<T>;
    function AddQueryParameter(const AName, AValue: string): IMandarinExtJson<T>;
    function AddUrlSegment(const AName, AValue: string): IMandarinExtJson<T>;
    function AddJsonPair(const AName, AValue: string): IMandarinExtJson<T>;
    function SetBodyRaw(const AValue: string): IMandarinExtJson<T>;
    function SetRequestMethod(const AValue: string): IMandarinExtJson<T>;
  end;

  TMandarinClientJson = class(TMandarinClient)
  private
    FSerializer: TJsonSerializer;
  public
    function NewMandarin<T>(const ABaseUrl: string = ''): IMandarinExtJson<T>;
    procedure Execute<T>(AMandarin: IMandarin; AResponseCallback: TProc<T, IHTTPResponse>;
      const AIsSyncMode: Boolean = True); reintroduce;
    procedure ExecuteSync<T>(AMandarin: IMandarin; AResponseCallback: TProc<T, IHTTPResponse>); reintroduce;
    procedure ExecuteAsync<T>(AMandarin: IMandarin; AResponseCallback: TProc<T, IHTTPResponse>); reintroduce;
    constructor Create; override;
    destructor Destroy; override;
    property Serializer: TJsonSerializer read FSerializer write FSerializer;
  end;

implementation

uses
  System.Types;

type
  TMandarinTools = class
  public
    class procedure Synchronize(const AThread: TThread; AThreadProc: TProc);
  end;

function TMandarin.AddQueryParameter(const AName, AValue: string): IMandarin;
begin
  FQueryParameters.AddOrSetValue(AName, AValue);
  Result := Self;
end;

function TMandarin.AddUrlSegment(const AName, AValue: string): IMandarin;
begin
  FUrlSegments.AddOrSetValue(AName, AValue);
  Result := Self;
end;

function TMandarin.BuildRequest(AHttpCli: THttpClient): IHTTPRequest;
begin
  SetupUrlSegments(FUrl);
  SetupQueryParameters(FUrl);
  Result := AHttpCli.GetRequest(FRequestMethod, FUrl);
  FBody.UpgradeHttpRequest(Result);
  SetupHeaders(Result);
end;

constructor TMandarin.Create;
begin
  Self.Create('');
end;

constructor TMandarin.Create(const AUrl: string);
begin
  inherited Create;
  FUrl := AUrl;
  FRequestMethod := 'GET';
  FHeaders := TDictionary<string, string>.Create();
  FUrlSegments := TDictionary<string, string>.Create();
  FQueryParameters := TDictionary<string, string>.Create();
  FBody := TMandarinBody.Create();
end;

destructor TMandarin.Destroy;
begin
  FBody.Free;
  FQueryParameters.Free;
  FUrlSegments.Free;
  FHeaders.Free;
  inherited Destroy;
end;

function TMandarin.AddHeader(const AName, AValue: string): IMandarin;
begin
  FHeaders.AddOrSetValue(AName, AValue);
  Result := Self;
end;

function TMandarin.GetBody: TMandarinBody;
begin
  Result := FBody;
end;

function TMandarin.GetRequestMethod: string;
begin
  Result := FRequestMethod;
end;

function TMandarin.GetUrl: string;
begin
  Result := FUrl;
end;

procedure TMandarin.SetRequestMethod(

  const Value: string);
begin
  FRequestMethod := Value;
end;

procedure TMandarin.SetupHeaders(ARequest: IHTTPRequest);
begin
  for var LHeader in FHeaders do
    ARequest.HeaderValue[LHeader.Key] := LHeader.Value;
end;

procedure TMandarin.SetupQueryParameters(var AUrl: string);
var
  LUrl: TURI;
begin
  LUrl := TURI.Create(AUrl);
  for var LQParameter in FQueryParameters do
    LUrl.AddParameter(LQParameter.Key, LQParameter.Value);
  AUrl := LUrl.ToString;
end;

procedure TMandarin.SetupUrlSegments(var AUrl: string);
begin
  for var LSegment in FUrlSegments do
    AUrl := AUrl.Replace('{' + LSegment.Key + '}', LSegment.Value);
end;

procedure TMandarin.SetUrl(const Value: string);
begin
  FUrl := Value;
end;

procedure TMandarinBody.BuildRaw(var ARequest: IHTTPRequest);
begin
  ARequest.SourceStream := TStringStream.Create(UTF8String(FRaw));
end;

constructor TMandarinBody.Create;
begin
  inherited;
  FJson := TJSONObject.Create;
  FRaw := '';
  FType := TMandarinBodyType.None;
end;

procedure TMandarinBody.SetRaw(const Value: string);
begin
  FRaw := Value;
  FType := TMandarinBodyType.Raw;
end;

procedure TMandarinBody.UpgradeHttpRequest(var ARequest: IHTTPRequest);
begin
  case FType of
    TMandarinBodyType.None:
      ;
    TMandarinBodyType.Raw:
      BuildRaw(ARequest);
  else
    raise ENotImplemented.Create('UpgradeHttpRequest');
  end;
end;

{ TMandarinTools }

class procedure TMandarinTools.Synchronize(const AThread: TThread; AThreadProc: TProc);
begin
  if IsConsole then
    AThreadProc()
  else
    TThread.Synchronize(AThread,
      procedure
      begin
        AThreadProc();
      end);
end;

constructor TMandarinClient.Create;
begin
  inherited;
  FHttp := THttpClient.Create;
  FHttp.UserAgent := 'TMandarin client';
end;

destructor TMandarinClient.Destroy;
begin
  FHttp.Free;
  inherited;
end;

procedure TMandarinClient.Execute(AMandarin: IMandarin; AResponseCallback: TProc<IHTTPResponse>;
const AIsSyncMode: Boolean = True);
begin
  if AIsSyncMode then
    ExecuteSync(AMandarin, AResponseCallback)
  else
    ExecuteAsync(AMandarin, AResponseCallback);
end;

procedure TMandarinClient.ExecuteAsync(AMandarin: IMandarin; AResponseCallback: TProc<IHTTPResponse>);
var
  LHttpRequest: IHTTPRequest;
begin
  LHttpRequest := AMandarin.BuildRequest(FHttp);
  if Assigned(OnBeforeExcecute) then
    OnBeforeExcecute(AMandarin);
  FHttp.BeginExecute(
    procedure(const ASyncResult: IAsyncResult)
    var
      LHttpResponse: IHTTPResponse;
    begin
      LHttpResponse := FHttp.EndAsyncHTTP(ASyncResult);
      if Assigned(AResponseCallback) then
        AResponseCallback(LHttpResponse);
    end, LHttpRequest, nil, nil);
end;

procedure TMandarinClient.ExecuteSync(AMandarin: IMandarin; AResponseCallback: TProc<IHTTPResponse>);
var
  LHttpRequest: IHTTPRequest;
  LHttpResponse: IHTTPResponse;
begin
  if Assigned(OnBeforeExcecute) then
    OnBeforeExcecute(AMandarin);
  LHttpRequest := AMandarin.BuildRequest(FHttp);

  LHttpResponse := FHttp.Execute(LHttpRequest);
  if Assigned(AResponseCallback) then
    AResponseCallback(LHttpResponse);
end;

function TMandarinClient.NewMandarin(const ABaseUrl: string = ''): IMandarinExt;
begin
  Result := TMandarinExt.Create(Self, ABaseUrl);
end;

{ TMandarinClientJson }

constructor TMandarinClientJson.Create;
begin
  inherited;
  FSerializer := TJsonSerializer.Create();
end;

destructor TMandarinClientJson.Destroy;
begin
  FSerializer.Free;
  inherited;
end;

procedure TMandarinClientJson.Execute<T>(AMandarin: IMandarin; AResponseCallback: TProc<T, IHTTPResponse>;
const AIsSyncMode: Boolean);
begin
  if AIsSyncMode then
    ExecuteSync<T>(AMandarin, AResponseCallback)
  else
    ExecuteAsync<T>(AMandarin, AResponseCallback);
end;

procedure TMandarinClientJson.ExecuteAsync<T>(AMandarin: IMandarin; AResponseCallback: TProc<T, IHTTPResponse>);
begin
  inherited ExecuteAsync(AMandarin,
    procedure(AHttp: IHTTPResponse)
    var
      LData: T;
    begin
      LData := FSerializer.Deserialize<T>(AHttp.ContentAsString(TEncoding.UTF8));
      AResponseCallback(LData, AHttp);
    end);
end;

procedure TMandarinClientJson.ExecuteSync<T>(AMandarin: IMandarin; AResponseCallback: TProc<T, IHTTPResponse>);
begin
  inherited ExecuteSync(AMandarin,
    procedure(AHttp: IHTTPResponse)
    var
      LData: T;
    begin
      LData := FSerializer.Deserialize<T>(AHttp.ContentAsString(TEncoding.UTF8));
      AResponseCallback(LData, AHttp);
    end);
end;

function TMandarinClientJson.NewMandarin<T>(const ABaseUrl: string): IMandarinExtJson<T>;
begin
  Result := TMandarinExtJson<T>.Create(Self, ABaseUrl);
end;

function TMandarinExt.AddHeader(const AName, AValue: string): IMandarinExt;
begin
  inherited AddHeader(AName, AValue);
  Result := Self;
end;

function TMandarinExt.AddQueryParameter(const AName, AValue: string): IMandarinExt;
begin
  inherited AddQueryParameter(AName, AValue);
  Result := Self;
end;

function TMandarinExt.AddUrlSegment(const AName, AValue: string): IMandarinExt;
begin
  inherited AddUrlSegment(AName, AValue);
  Result := Self;
end;

constructor TMandarinExt.Create(AClient: TMandarinClient; const ABaseUrl: string = '');
begin
  inherited Create(ABaseUrl);
  FClient := AClient;
end;

procedure TMandarinExt.Execute(AResponseCallback: TProc<IHTTPResponse>; AIsSync: Boolean);
begin
  FClient.Execute(Self, AResponseCallback, AIsSync);
end;

procedure TMandarinExt.ExecuteAsync(AResponseCallback: TProc<IHTTPResponse>);
begin
  FClient.ExecuteAsync(Self, AResponseCallback);
end;

procedure TMandarinExt.ExecuteSync(AResponseCallback: TProc<IHTTPResponse>);
begin
  FClient.ExecuteSync(Self, AResponseCallback);
end;

{ TMandarinExtJson<T> }

function TMandarinExtJson<T>.AddHeader(const AName, AValue: string): IMandarinExtJson<T>;
begin
  inherited AddHeader(AName, AValue);
  Result := Self;
end;

function TMandarinExtJson<T>.AddJsonPair(const AName, AValue: string): IMandarinExtJson<T>;
var
  LJson: TJSONObject;
begin
  LJson := TJSONObject.ParseJSONValue(Body.Raw) as TJSONObject;
  if LJson = nil then
    LJson := TJSONObject.Create;
  try
    LJson.AddPair(AName, AValue);
    Body.Raw := LJson.ToJSON;
  finally
    LJson.Free;
  end;
  Result := Self;
end;

function TMandarinExtJson<T>.AddQueryParameter(const AName, AValue: string): IMandarinExtJson<T>;
begin
  inherited AddQueryParameter(AName, AValue);
  Result := Self;
end;

function TMandarinExtJson<T>.AddUrlSegment(const AName, AValue: string): IMandarinExtJson<T>;
begin
  inherited AddUrlSegment(AName, AValue);
  Result := Self;
end;

constructor TMandarinExtJson<T>.Create(AClient: TMandarinClientJson; const ABaseUrl: string = '');
begin
  inherited Create(ABaseUrl);
  FClient := AClient;
  FUrl := ABaseUrl;
end;

procedure TMandarinExtJson<T>.Execute(AResponseCallback: TProc<T, IHTTPResponse>; const AIsSyncMode: Boolean);
begin
  FClient.Execute<T>(Self, AResponseCallback, AIsSyncMode);
end;

procedure TMandarinExtJson<T>.ExecuteAsync(AResponseCallback: TProc<T, IHTTPResponse>);
begin
  FClient.ExecuteAsync<T>(Self, AResponseCallback);
end;

procedure TMandarinExtJson<T>.ExecuteSync(AMandarin: IMandarin; AResponseCallback: TProc<T, IHTTPResponse>);
begin
  FClient.ExecuteSync<T>(Self, AResponseCallback);
end;

function TMandarinExtJson<T>.SetBodyRaw(const AValue: string): IMandarinExtJson<T>;
begin
  inherited Body.Raw := AValue;
  Result := Self;
end;

function TMandarinExtJson<T>.SetRequestMethod(const AValue: string): IMandarinExtJson<T>;
begin
  inherited SetRequestMethod(AValue);
  Result := Self;
end;

end.
