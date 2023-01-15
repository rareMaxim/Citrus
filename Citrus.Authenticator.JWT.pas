unit Citrus.Authenticator.JWT;

interface

uses
  Citrus.Mandarin;

type
  TJwtAuthenticator = class(TInterfacedObject, IAuthenticator)
  private
    FAccessToken: string;
    procedure SetAccessToken(const Value: string);
  protected
    procedure UpgradeMandarin(AMandarin: IMandarin);
  public
    property AccessToken: string read FAccessToken write SetAccessToken;
  end;

implementation

uses
  System.SysUtils;

{ TJwtAuthenticator }
procedure TJwtAuthenticator.SetAccessToken(const Value: string);
begin
  FAccessToken := Value;
end;

procedure TJwtAuthenticator.UpgradeMandarin(AMandarin: IMandarin);
begin
  if not AccessToken.IsEmpty then
    AMandarin.AddHeader('Authorization', 'Bearer ' + AccessToken);
end;

end.
