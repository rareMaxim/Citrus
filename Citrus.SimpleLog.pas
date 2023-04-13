unit Citrus.SimpleLog;

interface

uses
  System.SysUtils;

type
{$SCOPEDENUMS ON}
  TLogLevel = (Unknown, Trace, Debug, Text, Info, Warn, Error, Fatal);
{$SCOPEDENUMS OFF}

  TLogInfo = record
  private
    FTimestamp: TDateTime;
    FMessage: string;
    FLevel: TLogLevel;
    FException: Exception;
    FTag: string;
  public
    class function Create(const ALevel: TLogLevel; const AMessage: string; const ATag: string = '';
      AException: Exception = nil): TLogInfo; static;
    class function Fatal(const AMessage: string; const ATag: string = ''; AException: Exception = nil)
      : TLogInfo; static;
    class function Error(const AMessage: string; const ATag: string = ''; AException: Exception = nil)
      : TLogInfo; static;
    class function Warn(const AMessage: string; const ATag: string = ''; AException: Exception = nil): TLogInfo; static;
    class function Info(const AMessage: string; const ATag: string = ''): TLogInfo; static;

    property Level: TLogLevel read FLevel write FLevel;
    property Timestamp: TDateTime read FTimestamp write FTimestamp;
    property Message: string read FMessage write FMessage;
    property Exception: Exception read FException write FException;
    property Tag: string read FTag write FTag;
    function ToString: string;

  end;

implementation

uses
  System.Rtti;

{ TLogInfo }

class function TLogInfo.Create(const ALevel: TLogLevel; const AMessage: string; const ATag: string = '';
  AException: Exception = nil): TLogInfo;
begin
  Result.Timestamp := Now;
  Result.Level := ALevel;
  Result.Message := AMessage;
  Result.Exception := AException;
  Result.Tag := ATag;
end;

class function TLogInfo.Error(const AMessage: string; const ATag: string = ''; AException: Exception = nil): TLogInfo;
begin
  Result := TLogInfo.Create(TLogLevel.Error, AMessage, ATag, AException)
end;

class function TLogInfo.Fatal(const AMessage: string; const ATag: string = ''; AException: Exception = nil): TLogInfo;
begin
  Result := TLogInfo.Create(TLogLevel.Fatal, AMessage, ATag, AException)
end;

class function TLogInfo.Info(const AMessage: string; const ATag: string = ''): TLogInfo;
begin
  Result := TLogInfo.Create(TLogLevel.Info, AMessage, ATag);
end;

function TLogInfo.ToString: string;
var
  LTimeStamp: string;
  LLevel: string;
begin
  LTimeStamp := DateTimeToStr(FTimestamp);
  LLevel := TRttiEnumerationType.GetName<TLogLevel>(FLevel);
  Result := LTimeStamp + ' ';
  if not Tag.IsEmpty then
    Result := Result + ' ' + Tag;
  Result := Result + ': ' + LLevel;
  Result := Result + ': ' + FMessage;
  if Assigned(FException) then
    Result := Result + ': ' + FException.ToString;
end;

class function TLogInfo.Warn(const AMessage: string; const ATag: string = ''; AException: Exception = nil): TLogInfo;
begin
  Result := TLogInfo.Create(TLogLevel.Fatal, AMessage, ATag, AException)
end;

end.
