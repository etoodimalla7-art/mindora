"""Safe arithmetic calculator tool.

The tool only evaluates a whitelist of characters and Python AST nodes.
It is deliberately not a symbolic solver — for symbolic math (integrals,
derivatives with variables) we rely on the LLM's reasoning.
"""
from __future__ import annotations

import ast
import math
import operator
import re
from typing import Any

from ai.tools.base import ToolContext, ToolResult

_ALLOWED_OPERATORS: dict[type, Any] = {
    ast.Add: operator.add,
    ast.Sub: operator.sub,
    ast.Mult: operator.mul,
    ast.Div: operator.truediv,
    ast.FloorDiv: operator.floordiv,
    ast.Mod: operator.mod,
    ast.Pow: operator.pow,
    ast.USub: operator.neg,
    ast.UAdd: operator.pos,
}

_ALLOWED_NAMES: dict[str, float] = {
    "pi": math.pi,
    "e": math.e,
    "tau": math.tau,
    "inf": math.inf,
}

_ALLOWED_FUNCTIONS: dict[str, Any] = {
    "abs": abs,
    "round": round,
    "min": min,
    "max": max,
    "sum": sum,
    "sqrt": math.sqrt,
    "sin": math.sin,
    "cos": math.cos,
    "tan": math.tan,
    "asin": math.asin,
    "acos": math.acos,
    "atan": math.atan,
    "log": math.log,
    "log10": math.log10,
    "log2": math.log2,
    "exp": math.exp,
    "floor": math.floor,
    "ceil": math.ceil,
    "factorial": math.factorial,
    "gcd": math.gcd,
    "pow": pow,
}

# Detect a simple arithmetic expression in the user's message.
_MATH_PATTERN = re.compile(
    r"^[\s\d\.\+\-\*/\(\)\,%^a-zA-Z_]+$"
)


class CalculatorTool:
    name = "calculator"
    description = (
        "Evaluate arithmetic and standard mathematical expressions "
        "(sqrt, sin, cos, log, exp, factorial, constants pi and e). "
        "Use ONLY when the user's message is a plain calculation."
    )

    async def execute(self, ctx: ToolContext) -> ToolResult:
        expr = self._extract_expression(ctx.message)
        if not expr:
            return ToolResult(
                text="",
                tool_name=self.name,
                error="No arithmetic expression found.",
            )
        try:
            tree = ast.parse(expr, mode="eval")
            value = self._eval_node(tree.body)
            return ToolResult(
                text=f"{expr.strip()} = {value}",
                tool_name=self.name,
                metadata={"expression": expr.strip(), "value": value},
            )
        except Exception as exc:  # noqa: BLE001
            return ToolResult(
                text="",
                tool_name=self.name,
                error=f"Could not evaluate: {exc}",
            )

    # ---------- Helpers ----------

    @staticmethod
    def _extract_expression(message: str) -> str | None:
        # Strip trailing punctuation like "=?" or "?".
        s = message.strip().rstrip("?.! ")
        # Common prefixes to strip.
        for prefix in ("calculate", "compute", "what is", "what's", "eval", "="):
            if s.lower().startswith(prefix + " "):
                s = s[len(prefix) + 1 :].strip()
        # Only accept if it looks like pure arithmetic.
        if not _MATH_PATTERN.match(s):
            return None
        # Must contain at least one operator to be worth evaluating.
        if not re.search(r"[\+\-\*/%^\(\)]", s):
            return None
        # Replace ^ with ** for Python.
        return s.replace("^", "**")

    @classmethod
    def _eval_node(cls, node: ast.AST) -> Any:
        if isinstance(node, ast.Constant):
            if isinstance(node.value, (int, float)):
                return node.value
            raise ValueError("Only numeric constants are allowed.")
        if isinstance(node, ast.BinOp) and type(node.op) in _ALLOWED_OPERATORS:
            left = cls._eval_node(node.left)
            right = cls._eval_node(node.right)
            return _ALLOWED_OPERATORS[type(node.op)](left, right)
        if isinstance(node, ast.UnaryOp) and type(node.op) in _ALLOWED_OPERATORS:
            return _ALLOWED_OPERATORS[type(node.op)](cls._eval_node(node.operand))
        if isinstance(node, ast.Name) and node.id in _ALLOWED_NAMES:
            return _ALLOWED_NAMES[node.id]
        if isinstance(node, ast.Call):
            func = node.func
            if not isinstance(func, ast.Name) or func.id not in _ALLOWED_FUNCTIONS:
                raise ValueError(f"Function '{getattr(func, 'id', '?')}' is not allowed.")
            args = [cls._eval_node(a) for a in node.args]
            return _ALLOWED_FUNCTIONS[func.id](*args)
        raise ValueError(f"Unsupported expression element: {type(node).__name__}")
