vim.snippets.add("cpp", {
  {
    trig = "main",
    name = "main",
    dscr = "main with fast I/O",
    body = [[
#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    $0
    return 0;
}
]],
  },
  {
    trig = "fastio",
    name = "fastio",
    dscr = "fast I/O boilerplate",
    body = [[
    ios::sync_with_stdio(false);
    cin.tie(nullptr);
    $0]],
  },
  {
    trig = "fori",
    name = "fori",
    dscr = "index for loop",
    body = [[for (int ${1:i} = 0; ${1:i} < ${2:n}; ++${1:i}) {
    $0
}]],
  },
  {
    trig = "vpai",
    name = "vpai",
    dscr = "vector<pair<int,int>>",
    body = [[vector<pair<${1:int}, ${2:int}>> ${3:v};$0]],
  },
})
