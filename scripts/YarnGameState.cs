// scripts/YarnGameState.cs
using Godot;
using YarnSpinnerGodot;

namespace OutpostNova;

/// <summary>
/// Exposes GameState query methods as Yarn functions.
///
/// The <see cref="YarnFunctionAttribute"/> below is picked up by the YarnSpinner
/// source generator, but that generator is a locally-built analyzer DLL which
/// Windows Application Control can block (CSC warning CS8034). When that happens
/// no registration code is emitted and Yarn dies at runtime with
/// "Function get_flag is not present in the library". <see cref="Register"/> does
/// the same registration explicitly so dialogue works either way.
/// </summary>
public partial class YarnGameState : Node
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

    /// <summary>
    /// Registers every Yarn function on <paramref name="runner"/>. Called from
    /// GDScript (main.gd) right after the YarnProject is assigned. Re-registering
    /// an existing name is harmless — the runner replaces the entry.
    /// </summary>
    public void Register(DialogueRunner runner)
    {
        runner.AddFunction("get_flag", (System.Func<string, bool>)GetFlag);
    }
}
