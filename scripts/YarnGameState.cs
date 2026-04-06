// scripts/YarnGameState.cs
using Godot;
using YarnSpinnerGodot;

namespace OutpostNova;

/// <summary>
/// Exposes GameState query methods as Yarn functions.
/// Auto-registered by the YarnSpinner source generator — no manual registration needed.
/// </summary>
public static class YarnGameState
{
    /// <summary>
    /// Returns the value of a GameState flag.
    /// Usage in Yarn: &lt;&lt;if get_flag("workshop_unlocked")&gt;&gt;
    /// </summary>
    [YarnFunction("get_flag")]
    public static bool GetFlag(string flagId)
    {
        var sceneTree = (SceneTree)Engine.GetMainLoop();
        var gameState = sceneTree.Root.GetNode("GameState");
        return gameState.Call("get_flag", flagId).AsBool();
    }
}
