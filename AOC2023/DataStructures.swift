//
//  DataStructures.swift
//  AdventOfCode
//
//  Created by Nicolas Märki on 08.12.22.
//

import Foundation
import RegexBuilder

struct Grid<V>: CustomDebugStringConvertible {
    fileprivate var values: [[V]]
    init(width: Int, height: Int, initial: V) {
        values = [[V]].init(repeating: [V].init(repeating: initial, count: width), count: height)
    }

    init(lines: String, lineSeparator: String = "\n", columnSeparator: String = "", allowEmpty: Bool = true, fillMissing: V? = nil, map: (String) -> V) {
        self.init(lines: lines.components(separatedBy: lineSeparator).filter { !$0.isEmpty || allowEmpty }, columnSeparator: columnSeparator, allowEmpty: allowEmpty, fillMissing: fillMissing, map: map)
    }

    init(lines: [String], columnSeparator: String = "", allowEmpty: Bool = true, fillMissing: V? = nil, map: (String) -> V) {
        values = lines.map {
            if columnSeparator == "" {
                return $0.characters.filter { !$0.isEmpty || allowEmpty }.map(map)
            }
            else {
                return $0.components(separatedBy: columnSeparator).filter { !$0.isEmpty || allowEmpty }.map(map)
            }
        }
        if let fillMissing {
            let columns = values.map { $0.count }.max() ?? 0
            values = values.map { var v = $0
                while v.count < columns {
                    v.append(fillMissing)
                }
                return v
            }
        }

    }

    init(values: [[V]]) {
        self.values = values
    }

    init(width: Int, height: Int, compute: (Int, Int) -> V) {
        let values = (0 ..< height).map { y in (0 ..< width).map { x in compute(x,y) } }
        self.init(values: values)
    }

    subscript(_ x: Int, _ y: Int) -> V {
        get {
            values[y][x]
        }
        set {
            values[y][x] = newValue
        }
    }

    subscript(_ xy: Vec2D<Int>) -> V {
        get {
            values[xy.y][xy.x]
        }
        set {
            values[xy.y][xy.x] = newValue
        }
    }

    var rows: [[V]] {
        values
    }

    var columns: [[V]] {
        transposed().values
    }

    func subgrid<XS: GridRangeSequence, YS: GridRangeSequence>(_ xs: XS, _ ys: YS) -> Grid<V> {
        var lines = [[V]]()
        for y in ys.range(in: self, horizontal: false) {
            var line = [V]()
            for x in xs.range(in: self, horizontal: true) {
                line.append(self[x as! Int, y as! Int])
            }
            lines.append(line)
        }
        return Grid(values: lines)
    }

    func subgrid<XS: GridRangeSequence>(xs: XS) -> Grid<V> {
        subgrid(xs, 0..<height)
    }

    func subgrid<YS: GridRangeSequence>(ys: YS) -> Grid<V> {
        subgrid(0..<width, ys)
    }




    var height: Int {
        values.count
    }

    var width: Int {
        if values.isEmpty {
            return 0
        }
        return values[0].count
    }

    var size: (width: Int, height: Int) {
        (width: self.width, height: self.height)
    }

    func enumerated() -> [(x: Int, y: Int, v: V)] {
        if height == 0 || width == 0 {
            return []
        }
        var vals = [(x: Int, y: Int, v: V)]()
        for x in 0 ..< width {
            for y in 0 ..< height {
                vals.append((x: x, y: y, v: values[y][x]))
            }
        }
        return vals
    }

    func allValues() -> [V] {
        return enumerated().map { $0.v }
    }

    func reduceRows<Result>(_ initialResult: Result, _ nextPartialResult: (Result, V) -> Result) -> [Result] {
        values.map {
            $0.reduce(initialResult, nextPartialResult)
        }
    }

    func reduceColumns<Result>(_ initialResult: Result, _ nextPartialResult: (Result, V) -> Result) -> [Result] {
        transposed().values.map {
            $0.reduce(initialResult, nextPartialResult)
        }
    }

    func map<ResultV>(_ transform: (V) -> ResultV) -> Grid<ResultV> {
        Grid<ResultV>(values: values.map { $0.map { v in transform(v) } })
    }

    func transposed() -> Grid<V> {
        var values = [[V]]()
        for x in 0 ..< width {
            var newRow = [V]()
            for y in 0 ..< height {
                newRow.append(self[x, y])
            }
            values.append(newRow)
        }
        return Grid(values: values)
    }

    var debugDescription: String {
        String(values.map { String($0.map { String(describing: $0) }.joined(separator: "")) }.joined(separator: "\n"))
    }


}

protocol GridRangeSequence {
    func range<V>(in: Grid<V>, horizontal: Bool) -> any Sequence<Int>
}

extension Sequence<Int> {
    func range<V>(in: Grid<V>, horizontal: Bool) -> any Sequence<Int> {
        return self
    }
}

extension PartialRangeFrom<Int>: GridRangeSequence {
    func range<V>(in grid: Grid<V>, horizontal: Bool) -> any Sequence<Int> {
        return self.lowerBound ..< (horizontal ? grid.width : grid.height)
    }
}

extension PartialRangeUpTo<Int>: GridRangeSequence {
    func range<V>(in grid: Grid<V>, horizontal: Bool) -> any Sequence<Int> {
        return 0 ..< self.upperBound
    }
}

extension PartialRangeThrough<Int>: GridRangeSequence {
    func range<V>(in grid: Grid<V>, horizontal: Bool) -> any Sequence<Int> {
        return 0 ... self.upperBound
    }
}

extension Int: GridRangeSequence {
    func range<V>(in: Grid<V>, horizontal: Bool) -> any Sequence<Int> {
        return self...self
    }
}

extension StrideTo<Int>: GridRangeSequence {
    func range<V>(in: Grid<V>, horizontal: Bool) -> any Sequence<Int> {
        return self
    }
}

extension String {
    func parse<R>(@RegexComponentBuilder _ builder:  () -> Regex<R>) -> R {
        parse(builder())
    }
    func parse<R>(_ regex: Regex<R>) -> R {
        if let match = self.firstMatch(of: regex) {
            return match.output
        }
        fatalError("No match in \(self) for \(regex)")
    }
}


extension Range<Int>: GridRangeSequence {
    func range<V>(in: Grid<V>, horizontal: Bool) -> any Sequence<Int> {
        return self
    }
}

struct ScoredElement<V, C: Comparable>: Comparable {
    let element: V
    let score: C
    static func < (lhs: ScoredElement, rhs: ScoredElement) -> Bool { lhs.score < rhs.score }
    static func == (lhs: ScoredElement, rhs: ScoredElement) -> Bool { lhs.score == rhs.score }
    init(_ element: V, _ score: C) {
        self.element = element
        self.score = score
    }
}


struct GrowingGrid<V> {
    let defaultValue: V
    private(set) var grid: Grid<V>
    init(defaultValue: V) {
        self.defaultValue = defaultValue
        self.grid = Grid(values: [])
    }
    init(defaultValue: V, values: [(x: Int, y: Int, v: V)]) {
        self.init(defaultValue: defaultValue)
        for (x, y, v) in values {
            self[x, y] = v
        }
    }
    subscript(x: Int, y: Int) -> V {
        get {
            if x >= grid.width || y >= grid.height {
                return defaultValue
            }
            return grid[x, y]
        }
        set {
            if grid.values.isEmpty {
                grid.values.append([])
            }
            while grid.width <= x {
                for i in 0 ..< grid.values.count {
                    grid.values[i].append(defaultValue)
                }
            }
            while grid.height <= y {
                grid.values.append([V].init(repeating: defaultValue, count: grid.width))
            }
            grid[x, y] = newValue
        }
    }
    var height: Int {
        grid.height
    }
    var width: Int {
        grid.width
    }
}

extension Grid where V == Int {
    init(lines: String, lineSeparator: String = "\n", columnSeparator: String = "", fillMissing: Int? = nil) {
        self.init(lines: lines, lineSeparator: lineSeparator, columnSeparator: columnSeparator, fillMissing: fillMissing, map: { Int($0)! })
    }
}

extension Grid where V == Double {
    init(lines: String, lineSeparator: String = "\n", columnSeparator: String = "", fillMissing: Double? = nil) {
        self.init(lines: lines, lineSeparator: lineSeparator, columnSeparator: columnSeparator, fillMissing: fillMissing, map: { Double($0)! })
    }
}

extension Grid where V == String {
    init(lines: String, lineSeparator: String = "\n", columnSeparator: String = "", fillMissing: String? = nil) {
        self.init(lines: lines, lineSeparator: lineSeparator, columnSeparator: columnSeparator, fillMissing: fillMissing, map: { $0 })
    }
}

extension Grid where V == Int? {
    init(lines: String, lineSeparator: String = "\n", columnSeparator: String = " ") {
        self.init(lines: lines, lineSeparator: lineSeparator, columnSeparator: columnSeparator, map: { Int($0) })
    }
}

extension Grid where V == Double? {
    init(lines: String, lineSeparator: String = "\n", columnSeparator: String = " ") {
        self.init(lines: lines, lineSeparator: lineSeparator, columnSeparator: columnSeparator, map: { Double($0) })
    }
}

extension Grid {

    func neighbours4(at x: Int, y: Int) -> [(x: Int, y: Int, v: V)] {
        var ns = [(x: Int, y: Int, v: V)]()
        if x > 0 {
            ns.append((x: x-1, y: y, v: values[y][x-1]))
        }
        if y > 0 {
            ns.append((x: x, y: y-1, v: values[y-1][x]))
        }
        if x < width-1 {
            ns.append((x: x+1, y: y, v: values[y][x+1]))
        }
        if y < height-1 {
            ns.append((x: x, y: y+1, v: values[y+1][x]))
        }
        return ns
    }

    func graph4<EdgeValue>(makeEdge: ((p: Vec2D<Int>, v: V), (p: Vec2D<Int>, v: V)) -> EdgeValue?) -> Graph<Vec2D<Int>, V, EdgeValue> {
        typealias G = Graph<Vec2D<Int>, V, EdgeValue>
        let ns = enumerated()
        var nodes = [Vec2D<Int>: V]()
        var edges = [G.Edge: EdgeValue]()
        var neighbors = [Vec2D<Int>: [Vec2D<Int>]]()
        for n in ns {
            let me = Vec2D(n.x, n.y)
            nodes[me] = n.v
            for e in neighbours4(at: n.x, y: n.y) {
                let ne = Vec2D(e.x, e.y)
                if let ev = makeEdge((me, n.v), (ne, e.v)) {
                    edges[G.Edge(from: me, to: ne)] = ev
                    neighbors[me, default: []].append(ne)
                }
            }
        }
        return Graph(nodes: nodes, edges: edges, neighbors: neighbors)
    }
}

struct Graph<NodeKey: Hashable, NodeValue: Hashable, EdgeValue> {
    struct Edge: Hashable {
        let from: NodeKey
        let to: NodeKey
    }
    var nodes: [NodeKey: NodeValue]
    var edges: [Edge: EdgeValue]
    var neighbors: [NodeKey: [NodeKey]]
}


extension Array where Element == String {
    func mapInt() -> Array<Int> {
        self.map { Int($0.trimmingCharacters(in: .whitespacesAndNewlines))! }
    }
}

extension Array where Element == Substring {
    func mapInt() -> Array<Int> {
        self.map { Int($0.trimmingCharacters(in: .whitespacesAndNewlines))! }
    }
}

extension String: Error, LocalizedError {
    public var errorDescription: String? {
        self
    }
}

extension String {
    func regex(_ pattern: String) throws -> [String] {
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        guard let match = regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: utf16.count)) else {
            throw "No match for regex '\(pattern)' in '\(self)'"
        }
        var results: [String] = []
        for i in 1 ..< match.numberOfRanges {
            results.append(self[match.range(at: i)])
        }
        return results
    }

    subscript(i: Int) -> String {
        String(self[index(startIndex, offsetBy: i)])
    }

    subscript(r: Range<Int>) -> String {
        let startIndex = index(self.startIndex, offsetBy: r.lowerBound)
        let endIndex = index(self.startIndex, offsetBy: r.upperBound)
        let range: Range<String.Index> = startIndex ..< endIndex
        return String(self[range])
    }

    subscript(r: PartialRangeFrom<Int>) -> String {
        let startIndex = index(self.startIndex, offsetBy: r.lowerBound)
        let range: Range<String.Index> = startIndex ..< self.endIndex
        return String(self[range])
    }

    subscript(r: NSRange) -> String {
        let startIndex = index(self.startIndex, offsetBy: r.lowerBound)
        let endIndex = index(self.startIndex, offsetBy: r.upperBound)
        let range: Range<String.Index> = startIndex ..< endIndex
        return String(self[range])
    }

    func split2(separator: String = " ") -> (String, String) {
        let parts = components(separatedBy: separator)
        return (parts.at(0) ?? "", parts.at(1) ?? "")
    }

    func split3(separator: String = " ") -> (String, String, String) {
        let parts = components(separatedBy: separator)
        return (parts.at(0) ?? "", parts.at(1) ?? "", parts.at(2) ?? "")
    }

    func split4(separator: String = " ") -> (String, String, String, String) {
        let parts = components(separatedBy: separator)
        return (parts.at(0) ?? "", parts.at(1) ?? "", parts.at(2) ?? "", parts.at(3) ?? "")
    }

    func after(first: String, skip: Int = 0) -> String? {
        let parts = components(separatedBy: first).dropFirst(skip + 1)
        if parts.count > 0 {
            return parts.joined(separator: first)
        }
        return nil
    }

    func before(last: String, skip: Int = 0) -> String? {
        let parts = components(separatedBy: last).dropLast(skip + 1)
        if parts.count > 0 {
            return parts.joined(separator: last)
        }
        return nil
    }

    func between(_ start: String, and end: String) -> String {
        let (_, a) = split2(separator: start)
        let (b, _) = a.split2(separator: end)
        return b
    }

    func splitTwice(mainSeparator: String, lhsSeparator: String, rhsSeparator: String) -> (String, String, String, String) {
        if mainSeparator == lhsSeparator || mainSeparator == rhsSeparator {
            fatalError("mainSeparator must be unique")
        }
        let parts = components(separatedBy: mainSeparator)
        let (a, b) = (parts[0].split2(separator: lhsSeparator), parts[1].split2(separator: rhsSeparator))
        return (a.0, a.1, b.0, b.1)
    }

    var characters: [String] {
        self.unicodeScalars.map { String($0) }
    }


}

extension Array  {
    mutating func popLast(k: Int) -> Self {
        let e = self[count-k ..< count]
        self = Array(self.dropLast(k))
        return Array(e)
    }
    func at(_ index: Int) -> Element? {
        if index < count && index >= 0 {
            return self[index]
        }
        return nil
    }
    mutating func popFirst() -> Element? {
        let e = self.first
        if self.count <= 1 {
            self = []
        }
        else {
            self = Array(self[1...])
        }
        return e
    }
}

class TreeNode<V>: CustomDebugStringConvertible {
    private(set) var children: [TreeNode<V>] = []
    var v: V
    weak var parent: TreeNode<V>? = nil
    init(data: V) {
        self.v = data
    }
    @discardableResult func addNode(data: V) -> TreeNode<V> {
        let n = TreeNode(data: data)
        n.parent = self
        children.append(n)
        return n
    }
    var debugDescription: String {
        "\(v)\n" + children.map { c in
            c.debugDescription.components(separatedBy: "\n").map {
                "- " + $0
            }.joined(separator: "\n")
        }.joined(separator: "\n")
    }

    func propagateUp(_ initialResult: V, _ nextPartialResult: (V, V) -> V) -> TreeNode<V> {

        let newChildren = children.map { $0.propagateUp(initialResult, nextPartialResult) }
        let newData = newChildren.map { $0.v }.reduce(initialResult, nextPartialResult)
        let nodeValue = nextPartialResult(newData, self.v)
        let newNode = TreeNode<V>(data: nodeValue)
        newNode.children = newChildren
        return newNode
    }

    enum NodeType {
        case leaf
        case inner
        case all
        func match(leaf: Bool) -> Bool {
            switch self {
                case .all: return true
                case .leaf: return leaf
                case .inner: return !leaf
            }
        }
    }

    func filterNodes(_ type: NodeType, _ f: (TreeNode<V>) -> Bool) -> [TreeNode<V>] {
        var matched: [TreeNode<V>] = []
        if f(self) {
            matched.append(self)
        }
        for child in children where type.match(leaf: child.isLeaf) {
            matched.append(contentsOf: child.filterNodes(type, f))
        }
        return matched
    }

    var isLeaf: Bool {
        children.count == 0
    }

}

struct Vec2D<T: AdditiveArithmetic>: CustomDebugStringConvertible, Equatable {
    var x, y: T
    init(_ x: T, _ y: T) {
        self.x = x
        self.y = y
    }

    var debugDescription: String {
        "(\(x)|\(y))"
    }

    static func + (lhs: Self, rhs: Self) -> Self {
        Vec2D(lhs.x+rhs.x, lhs.y+rhs.y)
    }

    static func - (lhs: Self, rhs: Self) -> Self {
        Vec2D(lhs.x-rhs.x, lhs.y-rhs.y)
    }

    static func += (lhs: inout Self, rhs: Self) {
        lhs.x += rhs.x
        lhs.y += rhs.y
    }

    static func -= (lhs: inout Self, rhs: Self) {
        lhs.x -= rhs.x
        lhs.y -= rhs.y
    }
}

extension Vec2D: Hashable where T: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}

extension Vec2D where T == Int {
    init(string: String) {
        let xy = string.split(separator: ",").mapInt()
        self.x = xy[0]
        self.y = xy[1]
    }
}

struct Vec3D<T: AdditiveArithmetic>: CustomDebugStringConvertible, Equatable {
    var x, y, z: T
    init(_ x: T, _ y: T, _ z: T) {
        self.x = x
        self.y = y
        self.z = z
    }

    var debugDescription: String {
        "(\(x)|\(y)|\(z)"
    }

    static func + (lhs: Self, rhs: Self) -> Self {
        Vec3D(lhs.x+rhs.x, lhs.y+rhs.y, lhs.z+rhs.z)
    }

    static func - (lhs: inout Self, rhs: Self) -> Self {
        Vec3D(lhs.x-rhs.x, lhs.y-rhs.y, lhs.z-rhs.z)
    }

    static func += (lhs: inout Self, rhs: Self) {
        lhs.x += rhs.x
        lhs.y += rhs.y
        lhs.z += rhs.z
    }

    static func -= (lhs: inout Self, rhs: Self) {
        lhs.x -= rhs.x
        lhs.y -= rhs.y
        lhs.z -= rhs.z
    }
}

extension Vec3D: Hashable where T: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
        hasher.combine(z)
    }
}

extension Vec3D where T == Int {
    init(string: String) {
        let xyz = string.split(separator: ",").mapInt()
        self.x = xyz[0]
        self.y = xyz[1]
        self.z = xyz[2]
    }
}

protocol OptimizationState: Hashable {

    associatedtype Context

    func knownScore(_ context: Context) -> Int

    func expectedAdditionalScore(_ context: Context) -> Int

    func nextStates(_ context: Context) -> [Self]

}
