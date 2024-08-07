﻿unit Citrus.Mandarin;

interface

uses
  System.Generics.Collections,
  System.Net.HttpClient,
  System.Net.URLClient,
  System.Classes,
  System.JSON,
  System.JSON.Serializers,
  System.SyncObjs,
  System.SysUtils,
  Citrus.SimpleLog;

type
{$SCOPEDENUMS ON}
  TMandarinBodyType = (None, Raw, JSON);
{$SCOPEDENUMS OFF}
  IHTTPResponse = System.Net.HttpClient.IHTTPResponse;

  TMandarinBody = class
  private
    FRaw: string;
    FJSON: TJSONObject;
  protected
    procedure UpgradeHttpRequest(var ARequest: IHTTPRequest);
    procedure BuildRaw(const AData: string; var ARequest: IHTTPRequest);
  public
    constructor Create;
    destructor Destroy; override;
    function BodyType: TMandarinBodyType;
    property Raw: string read FRaw write FRaw;
    property JSON: TJSONObject read FJSON write FJSON;
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
    function GetUrlSegment(const AName: string): string;

    property RequestMethod: string read GetRequestMethod write SetRequestMethod;
    property Url: string read GetUrl write SetUrl;
    property Body: TMandarinBody read GetBody;
  end;

  IAuthenticator = interface
    ['{C400FE4B-8C97-4D91-B66E-0EF3C1D9FF4D}']
    procedure UpgradeMandarin(AMandarin: IMandarin);
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
    constructor Create(const AUrl: string = ''); overload;
    destructor Destroy; override;
    function AddHeader(const AName, AValue: string): IMandarin;
    function AddQueryParameter(const AName, AValue: string): IMandarin;
    function AddUrlSegment(const AName, AValue: string): IMandarin;
    function GetUrlSegment(const AName: string): string;
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
    function SetRequestMethod(const AValue: string): IMandarinExt;
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
    function SetRequestMethod(const AValue: string): IMandarinExt;
  end;

  TMandarinClient = class
  private
    FHttp: THttpClient;
    FOnBeforeExcecute: TProc<IMandarin>;
    FAuthenticator: IAuthenticator;
    FOnReadContentCallback: TFunc<IHTTPResponse, string>;
    FOnLog: TProc<TLogInfo>;
    procedure SetAuthenticator(const Value: IAuthenticator);
  protected
    function DoReadContent(AHttpResponse: IHTTPResponse): string;

  public
    procedure DoOnLog(ALog: TLogInfo); overload;
    procedure Execute(AMandarin: IMandarin; AResponseCallback: TProc<IHTTPResponse>; const AIsSyncMode: Boolean = True); virtual;
    procedure ExecuteSync(AMandarin: IMandarin; AResponseCallback: TProc<IHTTPResponse>); virtual;
    procedure ExecuteAsync(AMandarin: IMandarin; AResponseCallback: TProc<IHTTPResponse>); virtual;
    function NewMandarin(const ABaseUrl: string = ''): IMandarinExt; overload;
    constructor Create; virtual;
    destructor Destroy; override;
    property Http: THttpClient read FHttp write FHttp;
    property Authenticator: IAuthenticator read FAuthenticator write SetAuthenticator;
    property OnBeforeExcecute: TProc<IMandarin> read FOnBeforeExcecute write FOnBeforeExcecute;
    property OnReadContentCallback: TFunc<IHTTPResponse, string> read FOnReadContentCallback write FOnReadContentCallback;
    property OnLog: TProc<TLogInfo> read FOnLog write FOnLog;
  end;

  TMandarinClientGroupe = class
  private
    FMandarinClient: TMandarinClient;
    FMandarinList: TList<IMandarin>;
    FResponseList: TList<IHTTPResponse>;
    FOnResponse: TProc<TArray<IHTTPResponse>>;
  protected
    procedure DoRun(const IsAsyncMode: Boolean);
    procedure DoCallEndCallback;
  public
    constructor Create(AMandarinClient: TMandarinClient);
    destructor Destroy; override;
    procedure ExecuteAsyncGroup(AMandarins: TArray<IMandarin>; AResponseCallback: TProc < TArray < IHTTPResponse >> ); virtual;
    procedure ExecuteSyncGroup(AMandarins: TArray<IMandarin>; AResponseCallback: TProc < TArray < IHTTPResponse >> ); virtual;
    procedure ExecuteGroup(AMandarins: TArray<IMandarin>; AResponseCallback: TProc<TArray<IHTTPResponse>>;
      const IsAsyncMode: Boolean); virtual;
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
    function SetBody(ABody: TObject): IMandarinExtJson<T>;
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
    function SetBodyRaw(const AValue: string): IMandarinExtJson<T>;
    function SetRequestMethod(const AValue: string): IMandarinExtJson<T>;
    function SetBody(ABody: TObject): IMandarinExtJson<T>;
  end;

  TMandarinClientJson = class(TMandarinClient)
  private
    FSerializer: TJsonSerializer;
  public
    function NewMandarin(const ABaseUrl: string = ''): IMandarinExt; overload;
    function NewMandarin<T>(const ABaseUrl: string = ''): IMandarinExtJson<T>; overload;
    procedure Execute<T>(AMandarin: IMandarin; AResponseCallback: TProc<T, IHTTPResponse>; const AIsSyncMode: Boolean = True);
      reintroduce; overload;
    procedure Execute(AMandarin: IMandarin; AResponseCallback: TProc<IHTTPResponse>; const AIsSyncMode: Boolean = True); reintroduce;
      overload; virtual;
    procedure ExecuteSync<T>(AMandarin: IMandarin; AResponseCallback: TProc<T, IHTTPResponse>); reintroduce;
    procedure ExecuteAsync<T>(AMandarin: IMandarin; AResponseCallback: TProc<T, IHTTPResponse>); reintroduce;
    function Deserialize<T>(const AData: string): T;
    constructor Create; override;
    destructor Destroy; override;
    property Serializer: TJsonSerializer read FSerializer write FSerializer;
  end;

  TMandarinLongPooling = class
  private
    FCli: TMandarinClient;
    FInterval: Integer;
    FEvent: TEvent;
    FWorker: TThread;
    FOnGetMandarinCallback: TFunc<IMandarin>;
    FOnResponseCallback: TProc<IHTTPResponse>;
  protected
    procedure Go;
  public
    constructor Create(AClient: TMandarinClient);
    procedure Start; virtual;
    procedure Stop;
    destructor Destroy; override;
    property Interval: Integer read FInterval write FInterval;
    property OnGetMandarinCallback: TFunc<IMandarin> read FOnGetMandarinCallback write FOnGetMandarinCallback;
    property OnResponseCallback: TProc<IHTTPResponse> read FOnResponseCallback write FOnResponseCallback;
  end;

  IMandarinBodyBuider = interface
    ['{D2AD2C5B-D245-48A7-8EF3-E3E959FA966B}']
    function BuildBody: string;
  end;

implementation

uses
  System.Types;

{ TMandarin }
function TMandarin.AddQueryParameter(const AName, AValue: string): IMandarin;
begin
  FQueryParameters.AddOrSetValue(AName, AValue);
  Result := Self;
end;

function TMandarin.AddUrlSegment(const AName, AValue: string): IMandarin;
begin
  FUrlSegments.Add(AName, AValue);
  Result := Self;
end;

function TMandarin.BuildRequest(AHttpCli: THttpClient): IHTTPRequest;
begin
  SetupUrlSegments(FUrl);
  SetupQueryParameters(FUrl);
  Result := AHttpCli.GetRequest(FRequestMethod, FUrl);
  case FBody.BodyType of
    TMandarinBodyType.Raw:
      FBody.UpgradeHttpRequest(Result);
    TMandarinBodyType.JSON:
      begin
        FBody.UpgradeHttpRequest(Result);
        AddHeader('Content-Type', 'application/json');
      end;
  end;

  SetupHeaders(Result);
end;

constructor TMandarin.Create(const AUrl: string = '');
begin
  inherited Create;
  FUrl := AUrl;
  FRequestMethod := sHTTPMethodGet;
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

function TMandarin.GetUrlSegment(const AName: string): string;
begin
  if not FUrlSegments.TryGetValue(AName, Result) then
    Result := '';
end;

procedure TMandarin.SetRequestMethod(const Value: string);
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

{ TMandarinBody }

procedure TMandarinBody.BuildRaw(const AData: string; var ARequest: IHTTPRequest);
begin
  ARequest.SourceStream := TStringStream.Create(UTF8String(AData));
end;

constructor TMandarinBody.Create;
begin
  inherited Create();
  FRaw := '';
  FJSON := TJSONObject.Create();
end;

destructor TMandarinBody.Destroy;
begin
  FJSON.Free;
  inherited Destroy;
end;

function TMandarinBody.BodyType: TMandarinBodyType;
begin
  if not FRaw.IsEmpty then
    Result := TMandarinBodyType.Raw
  else if FJSON.Count > 0 then
    Result := TMandarinBodyType.JSON
  else
    Result := TMandarinBodyType.None;
end;

procedure TMandarinBody.UpgradeHttpRequest(var ARequest: IHTTPRequest);
begin
  case BodyType of
    TMandarinBodyType.JSON:
      BuildRaw(JSON.ToJSON, ARequest);
    TMandarinBodyType.Raw:
      BuildRaw(Raw, ARequest);
  end;
end;

{ TMandarinClient }
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

procedure TMandarinClient.DoOnLog(ALog: TLogInfo);
begin
  if Assigned(OnLog) then
    OnLog(ALog);
end;

function TMandarinClient.DoReadContent(AHttpResponse: IHTTPResponse): string;
begin
  if Assigned(OnReadContentCallback) then
    Result := OnReadContentCallback(AHttpResponse)
  else
    Result := AHttpResponse.ContentAsString(TEncoding.UTF8);
end;

procedure TMandarinClient.Execute(AMandarin: IMandarin; AResponseCallback: TProc<IHTTPResponse>; const AIsSyncMode: Boolean = True);
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
  if Assigned(FAuthenticator) then
    FAuthenticator.UpgradeMandarin(AMandarin);
  if Assigned(OnBeforeExcecute) then
    OnBeforeExcecute(AMandarin);
  LHttpRequest := AMandarin.BuildRequest(FHttp);

  FHttp.BeginExecute(
    procedure(const ASyncResult: IAsyncResult)
    var
      LHttpResponse: IHTTPResponse;
    begin
      try
        LHttpResponse := FHttp.EndAsyncHTTP(ASyncResult);
        if Assigned(AResponseCallback) then
          AResponseCallback(LHttpResponse);
      finally
        LHttpRequest.SourceStream.Free;
      end;
    end, LHttpRequest, nil, nil);
end;

procedure TMandarinClient.ExecuteSync(AMandarin: IMandarin; AResponseCallback: TProc<IHTTPResponse>);
var
  LHttpRequest: IHTTPRequest;
  LHttpResponse: IHTTPResponse;
begin
  if Assigned(FAuthenticator) then
    FAuthenticator.UpgradeMandarin(AMandarin);
  if Assigned(OnBeforeExcecute) then
    OnBeforeExcecute(AMandarin);
  LHttpRequest := AMandarin.BuildRequest(FHttp);
  try
    LHttpResponse := FHttp.Execute(LHttpRequest);
    if Assigned(AResponseCallback) then
      AResponseCallback(LHttpResponse);
  finally
    LHttpRequest.SourceStream.Free;
  end;
end;

function TMandarinClient.NewMandarin(const ABaseUrl: string = ''): IMandarinExt;
begin
  Result := TMandarinExt.Create(Self, ABaseUrl);
end;

procedure TMandarinClient.SetAuthenticator(const Value: IAuthenticator);
begin
  FAuthenticator := Value;
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

procedure TMandarinClientJson.Execute(AMandarin: IMandarin; AResponseCallback: TProc<IHTTPResponse>; const AIsSyncMode: Boolean = True);
begin
  inherited Execute(AMandarin, AResponseCallback, AIsSyncMode);
end;

procedure TMandarinClientJson.Execute<T>(AMandarin: IMandarin; AResponseCallback: TProc<T, IHTTPResponse>;
const AIsSyncMode: Boolean = True);
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
      LData := Deserialize<T>(DoReadContent(AHttp));
      if Assigned(AResponseCallback) then
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
      LData := Deserialize<T>(DoReadContent(AHttp));
      if Assigned(AResponseCallback) then
        AResponseCallback(LData, AHttp);
    end);
end;

function TMandarinClientJson.NewMandarin(const ABaseUrl: string): IMandarinExt;
begin
  Result := inherited NewMandarin(ABaseUrl);
end;

function TMandarinClientJson.NewMandarin<T>(const ABaseUrl: string): IMandarinExtJson<T>;
begin
  Result := TMandarinExtJson<T>.Create(Self, ABaseUrl);
end;

function TMandarinClientJson.Deserialize<T>(const AData: string): T;
begin
  Result := FSerializer.Deserialize<T>(AData);
end;

{ TMandarinExt }
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

function TMandarinExt.SetRequestMethod(const AValue: string): IMandarinExt;
begin
  inherited SetRequestMethod(AValue);
  Result := Self;
end;

{ TMandarinExtJson<T> }

function TMandarinExtJson<T>.AddHeader(const AName, AValue: string): IMandarinExtJson<T>;
begin
  inherited AddHeader(AName, AValue);
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

function TMandarinExtJson<T>.SetBody(ABody: TObject): IMandarinExtJson<T>;
var
  LBodyToJson: string;
  LSerializer: TJsonSerializer;
begin
  LSerializer := TJsonSerializer.Create;
  try
    LBodyToJson := LSerializer.Serialize<TObject>(ABody);
    SetBodyRaw(LBodyToJson);
    Result := Self;
  finally
    LSerializer.Free;
  end;
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

{ TMandarinLongPooling }
constructor TMandarinLongPooling.Create(AClient: TMandarinClient);
begin
  inherited Create;
  FInterval := 1000;
  FEvent := TEvent.Create();
  FCli := AClient;
end;

destructor TMandarinLongPooling.Destroy;
begin
  FEvent.Free;
  inherited;
end;

procedure TMandarinLongPooling.Go;
var
  LMandarin: IMandarin;
begin
  if Assigned(FOnGetMandarinCallback) then
    LMandarin := FOnGetMandarinCallback();
  FCli.ExecuteAsync(LMandarin, FOnResponseCallback);
end;

procedure TMandarinLongPooling.Start;
begin
  if Assigned(FWorker) then
    Exit;
  FWorker := TThread.CreateAnonymousThread(
    procedure
    var
      lWaitResult: TWaitResult;
    begin
      while True do
      begin
        lWaitResult := FEvent.WaitFor(FInterval);
        if lWaitResult = wrTimeout then
          Go
        else
          Break;
      end;
    end);
  FWorker.FreeOnTerminate := False;
  FWorker.Start;
end;

procedure TMandarinLongPooling.Stop;
begin
  FEvent.SetEvent;
  if Assigned(FWorker) then
    FWorker.WaitFor;
  FreeAndNil(FWorker);
end;

constructor TMandarinClientGroupe.Create(AMandarinClient: TMandarinClient);
begin
  inherited Create;
  FMandarinClient := AMandarinClient;
  FMandarinList := TList<IMandarin>.Create();
  FResponseList := TList<IHTTPResponse>.Create();
end;

destructor TMandarinClientGroupe.Destroy;
begin
  FResponseList.Free;
  FMandarinList.Free;
  inherited Destroy;
end;

procedure TMandarinClientGroupe.DoCallEndCallback;
begin
  if Assigned(FOnResponse) then
    FOnResponse(FResponseList.ToArray);
end;

procedure TMandarinClientGroupe.DoRun(const IsAsyncMode: Boolean);
begin
  if FMandarinList.Count = 0 then
    Exit; // ?
  FMandarinClient.Execute(FMandarinList.First,
    procedure(AHttpResponse: IHTTPResponse)
    begin
      FResponseList.Add(AHttpResponse);
      FMandarinList.Delete(0);
      if FMandarinList.Count = 0 then
        DoCallEndCallback
      else
        DoRun(IsAsyncMode);
    end, not IsAsyncMode);
end;

procedure TMandarinClientGroupe.ExecuteAsyncGroup(AMandarins: TArray<IMandarin>; AResponseCallback: TProc < TArray < IHTTPResponse >> );
begin
  ExecuteGroup(AMandarins, AResponseCallback, True);
end;

procedure TMandarinClientGroupe.ExecuteGroup(AMandarins: TArray<IMandarin>; AResponseCallback: TProc<TArray<IHTTPResponse>>;
const IsAsyncMode: Boolean);
begin
  FOnResponse := AResponseCallback;
  FMandarinList.AddRange(AMandarins);
  DoRun(IsAsyncMode);
end;

procedure TMandarinClientGroupe.ExecuteSyncGroup(AMandarins: TArray<IMandarin>; AResponseCallback: TProc < TArray < IHTTPResponse >> );
begin
  ExecuteGroup(AMandarins, AResponseCallback, False);
end;

end.
