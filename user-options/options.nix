{
  # general
  username = builtins.getEnv "USER";
  isDesktop = false;

  # git
  gitUsername = builtins.getEnv "GIT_USERNAME";
  gitEmail = builtins.getEnv "GIT_EMAIL";

  # open_ai
  openaiKey = builtins.getEnv "OPENAI_KEY";
}
