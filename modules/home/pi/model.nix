# Helpers for `programs.pi-coding-agent.models` and the matching `enabledModels`.
#
# Emit only the fields a host passes. `models.json` is generated from these
# attrsets, so inventing defaults (reasoning, cost, input) would silently
# change what pi assumes about a model that was deliberately left unspecified.
lib:
let
  mkModel =
    { id
    , contextWindow
    , maxTokens
    , name ? null
    , reasoning ? null
    , input ? null
    , cost ? null
    }:
    {
      inherit id contextWindow maxTokens;
    }
    // lib.optionalAttrs (name != null) { inherit name; }
    // lib.optionalAttrs (reasoning != null) { inherit reasoning; }
    // lib.optionalAttrs (input != null) { inherit input; }
    // lib.optionalAttrs (cost != null) { inherit cost; };

  # Self-hosted models are free, text-only and reasoning-capable, so those
  # fields repeat verbatim in every entry. Same output as passing them by
  # hand; only the repetition goes away.
  mkLocalModel =
    { id
    , contextWindow
    , maxTokens
    , name ? null
    , reasoning ? true
    , input ? [ "text" ]
    }:
    mkModel {
      inherit id contextWindow maxTokens name reasoning input;
      cost = {
        input = 0;
        output = 0;
        cacheRead = 0;
        cacheWrite = 0;
      };
    };
in
{
  inherit mkModel mkLocalModel;

  # `enabledModels` is "<provider>/<id>" for every model of every provider.
  # Listing it by hand lets a model be added to a provider and stay
  # unselectable; deriving it from the same attrset makes that impossible.
  # The provider order is passed in explicitly because `attrNames` sorts
  # alphabetically, and the order is what pi shows in its model picker.
  mkEnabledModels = order: providers:
    builtins.concatLists (
      builtins.map
        (name: builtins.map (m: "${name}/${m.id}") providers.${name}.models)
        order
    );
}
