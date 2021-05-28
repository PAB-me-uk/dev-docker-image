if git config --system credential.helper| grep -q 'vscode'; then
  sudo git config --system --unset credential.helper
fi

if git config --global credential.helper| grep -q 'vscode'; then
  git config --global credential.helper "!aws codecommit credential-helper --profile transporeon-prod \$@"
  git config --global credential.UseHttpPath true
fi