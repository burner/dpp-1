import reggae;
mixin build!(dubDefaultTarget!(),
             dubTestTarget!(),
             dubConfigurationTarget!(Configuration("integration"),
                                     Flags("-unittest")));