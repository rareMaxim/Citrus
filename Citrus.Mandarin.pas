unit Citrus.Mandarin;

interface

uses
  System.Generics.Collections,
  System.Net.HttpClient,
  System.Net.URLClient,
  System.Classes, System.SysUtils;

type
{$SCOPEDENUMS ON}
  TMandarinBodyType = (None, Raw);
{$SCOPEDENUMS OFF}

  TMandarinBody = class
  private
    FRaw: string;
    FType: TMandarinBodyType;
  protected
    procedure UpgradeHttpRequest(var ARequest: IHTTPRequest);
    procedure BuildRaw(var ARequest: IHTTPRequest);
  public
    constructor Create;
    property Raw: string read FRaw write FRaw;
    property &Type: TMandarinBodyType read FType write FType;
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
    procedure AddHeader(const AName, AValue: string);
    procedure AddQueryParameter(const AName, AValue: string);
    procedure AddUrlSegment(const AName, AValue: string);

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
    constructor Create;
    destructor Destroy; override;
    procedure AddHeader(const AName, AValue: string);
    procedure AddQueryParameter(const AName, AValue: string);
    procedure AddUrlSegment(const AName, AValue: string);

    property Url: string read GetUrl write SetUrl;
    property Headers: TDictionary<string, string> read FHeaders;
    property UrlSegments: TDictionary<string, string> read FUrlSegments;
    property QueryParameters: TDictionary<string, string> read FQueryParameters;
    property RequestMethod: string read GetRequestMethod write SetRequestMethod;
    property Body: TMandarinBody read GetBody;
  end;

  TMandarinClient = class
  private
    FHttp: THttpClient;

  public
    procedure Execute(AMandarin: IMandarin; AResponseCallback: TProc<IHTTPResponse>);
    procedure ExecuteAsync(AMandarin: IMandarin; AResponseCallback: TProc<IHTTPResponse>); virtual;
    constructor Create;
    destructor Destroy; override;

  end;

implementation

uses
  System.Types;

type
  TMandarinTools = class
  public
    class procedure Synchronize(const AThread: TThread; AThreadProc: TProc);
  end;

procedure TMandarin.AddQueryParameter(const AName, AValue: string);
begin
  FQueryParameters.AddOrSetValue(AName, AValue);
end;

procedure TMandarin.AddUrlSegment(const AName, AValue: string);
begin
  FUrlSegments.AddOrSetValue(AName, AValue);
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
  inherited Create;
  FRequestMethod := 'GET';
  FHeaders := TDictionary<string, string>.Create();
  FUrlSegments := TDictionary<string, string>.Create();
  FQueryParameters := TDictionary<string, string>.Create();
  FBody := TMandarinBody.Create();
  AddHeader('User-Agent', 'TMandarin client');
end;

destructor TMandarin.Destroy;
begin
  FBody.Free;
  FQueryParameters.Free;
  FUrlSegments.Free;
  FHeaders.Free;
  inherited Destroy;
end;

procedure TMandarin.AddHeader(const AName, AValue: string);
begin
  FHeaders.AddOrSetValue(AName, AValue);
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
  FRaw := '';
  FType := TMandarinBodyType.None;
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
end;

destructor TMandarinClient.Destroy;
begin
  FHttp.Free;
  inherited;
end;

procedure TMandarinClient.Execute(AMandarin: IMandarin; AResponseCallback: TProc<IHTTPResponse>);
var
  LHttpRequest: IHTTPRequest;
  LHttpResponse: IHTTPResponse;
begin
  LHttpRequest := AMandarin.BuildRequest(FHttp);
  LHttpResponse := FHttp.Execute(LHttpRequest);
  if Assigned(AResponseCallback) then
    AResponseCallback(LHttpResponse);
end;

procedure TMandarinClient.ExecuteAsync(AMandarin: IMandarin; AResponseCallback: TProc<IHTTPResponse>);
var
  LHttpRequest: IHTTPRequest;
begin
  LHttpRequest := AMandarin.BuildRequest(FHttp);
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

end.
