unit Citrus.Types;

interface

type
{$SCOPEDENUMS ON}
  TCitrusParameterType = (GetOrPost, UrlSegment, HttpHeader, RequestBodyRaw, //
    RequestBodyMultiPart, QueryString);
{$SCOPEDENUMS OFF}

implementation

uses
  System.SysUtils;

end.
