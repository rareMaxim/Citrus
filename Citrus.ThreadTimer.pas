unit Citrus.ThreadTimer;

interface

uses
  System.SyncObjs,
  System.Classes,
  System.SysUtils;

type
  TThreadTimer = class
  private
    FEvent: TEvent;
    FWorker: TThread;
    FInterval: Int64;
    FTimerCallback: TProc;
  protected
    procedure DoCallTimerCallback;
  public
    constructor Create(ATimerCallback: TProc); overload;
    procedure Start; virtual;
    procedure Stop;
    destructor Destroy; override;
    property Interval: Int64 read FInterval write FInterval;
    property TimerCallback: TProc read FTimerCallback write FTimerCallback;
  end;

implementation

{ TThreadTimer }

constructor TThreadTimer.Create(ATimerCallback: TProc);
begin
  inherited Create();
  FEvent := TEvent.Create();
  FInterval := 1000;
  FTimerCallback := ATimerCallback;
end;

destructor TThreadTimer.Destroy;
begin
  Stop;
  FEvent.Free;
  inherited Destroy;
end;

procedure TThreadTimer.DoCallTimerCallback;
begin
  if Assigned(FTimerCallback) then
    FTimerCallback();
end;

procedure TThreadTimer.Start;
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
          DoCallTimerCallback
        else
          Break;
      end;
    end);
  FWorker.FreeOnTerminate := False;
  FWorker.Start;
end;

procedure TThreadTimer.Stop;
begin
  FEvent.SetEvent;
  if Assigned(FWorker) then
    FWorker.WaitFor;
  FreeAndNil(FWorker);
end;

end.
