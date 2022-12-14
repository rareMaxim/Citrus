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

procedure TJwtAuthenticator.SetAccessToken(const Value: string);
begin
  FAccessToken := Value;
end;

{ TJwtAuthenticator }

procedure TJwtAuthenticator.UpgradeMandarin(AMandarin: IMandarin);
begin
  if not AccessToken.isempty then
    AMandarin.AddHeader('Authorization', 'Bearer ' + AccessToken);
end;

end.
