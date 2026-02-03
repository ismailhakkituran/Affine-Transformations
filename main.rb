#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"

class Point
  attr_reader :x, :y

  def initialize(x, y)
    @x = x.to_f
    @y = y.to_f
  end

  def to_a
    [x, y]
  end

  def to_s
    format("(%.4f, %.4f)", x, y)
  end
end

class Polygon
  attr_reader :points

  def initialize(points)
    raise ArgumentError, "Polygon needs at least 3 points" if points.length < 3

    @points = points
  end

  # Apply affine transform: [ [a, b], [c, d] ] + [tx, ty]
  def affine(a, b, c, d, tx = 0.0, ty = 0.0)
    new_points = points.map do |p|
      x = a * p.x + b * p.y + tx
      y = c * p.x + d * p.y + ty
      Point.new(x, y)
    end
    Polygon.new(new_points)
  end

  def translate(dx, dy)
    affine(1, 0, 0, 1, dx, dy)
  end

  def scale(sx, sy = nil)
    sy = sx if sy.nil?
    cx, cy = centroid
    tx = cx - sx * cx
    ty = cy - sy * cy
    affine(sx, 0, 0, sy, tx, ty)
  end

  def rotate(degrees)
    radians = degrees.to_f * Math::PI / 180.0
    cos_t = Math.cos(radians)
    sin_t = Math.sin(radians)
    affine(cos_t, -sin_t, sin_t, cos_t, 0, 0)
  end

  def shear(shx, shy)
    affine(1, shx, shy, 1, 0, 0)
  end

  def reflect(axis)
    case axis
    when :x
      affine(1, 0, 0, -1, 0, 0)
    when :y
      affine(-1, 0, 0, 1, 0, 0)
    when :origin
      affine(-1, 0, 0, -1, 0, 0)
    when :y_eq_x
      affine(0, 1, 1, 0, 0, 0)
    else
      raise ArgumentError, "Unknown axis: #{axis}"
    end
  end

  def to_s
    points.map(&:to_s).join(" ")
  end

  def centroid
    sum_x = points.sum(&:x)
    sum_y = points.sum(&:y)
    [sum_x / points.length, sum_y / points.length]
  end
end

def print_polygon(label, polygon)
  puts "#{label}:"
  polygon.points.each_with_index do |p, i|
    puts format("  P%-2d %s", i + 1, p.to_s)
  end
  puts
end

def mat_vec_mul(m, v)
  [
    m[0][0] * v[0] + m[0][1] * v[1],
    m[1][0] * v[0] + m[1][1] * v[1]
  ]
end

def mat_inverse_transpose(m)
  det = m[0][0] * m[1][1] - m[0][1] * m[1][0]
  raise ArgumentError, "Matrix is singular" if det.zero?

  inv = [
    [m[1][1] / det, -m[0][1] / det],
    [-m[1][0] / det, m[0][0] / det]
  ]
  [
    [inv[0][0], inv[1][0]],
    [inv[0][1], inv[1][1]]
  ]
end

def dot(a, b)
  a[0] * b[0] + a[1] * b[1]
end

def perpendicular(v)
  [-v[1], v[0]]
end

def run_normal_demo
  puts "Normal Dönüşümü (Inverse Transpose) Örneği"
  puts "-" * 50

  p1 = Point.new(0, 0)
  p2 = Point.new(3, 1)
  tangent = [p2.x - p1.x, p2.y - p1.y]
  normal = perpendicular(tangent)

  m = [
    [1.5, 0.4],
    [0.0, 0.5]
  ]

  t_trans = mat_vec_mul(m, tangent)
  n_wrong = mat_vec_mul(m, normal)
  n_right = mat_vec_mul(mat_inverse_transpose(m), normal)

  puts "Tangent: #{tangent.inspect}"
  puts "Normal:  #{normal.inspect}"
  puts "M:       #{m.inspect}"
  puts "M*t:     #{t_trans.inspect}"
  puts "M*n (yanlis): #{n_wrong.inspect}  dot(M*t, M*n)=#{dot(t_trans, n_wrong).round(6)}"
  puts "inv(M)^T*n (dogru): #{n_right.inspect}  dot(M*t, invT*n)=#{dot(t_trans, n_right).round(6)}"
  puts
end

if __FILE__ == $PROGRAM_NAME
  run_normal_demo if ARGV.include?("--normal-demo")

  polygon = Polygon.new(
    [
      Point.new(1, 1),
      Point.new(4, 1),
      Point.new(3, 3),
      Point.new(1, 4)
    ]
  )

  samples = [
    ["Orijinal Poligon", polygon, "white"],
    ["Öteleme (dx=2, dy=-1)", polygon.translate(2, -1), "red"],
    ["Ölçekleme (s=1.5)", polygon.scale(1.5), "green"],
    ["Dönme (45°)", polygon.rotate(45), "yellow"],
    ["Eğme (shx=0.5, shy=0.0)", polygon.shear(0.5, 0.0), "blue"],
    ["Yansıma (x ekseni)", polygon.reflect(:x), "yellow"],
    ["Genel Afin (a=1, b=0.2, c=-0.3, d=1, tx=1, ty=2)",
     polygon.affine(1, 0.2, -0.3, 1, 1, 2), "orange"]
  ]

  if ARGV.include?("--gui")
    begin
      require "ruby2d"
    rescue LoadError
      warn "Ruby2D gem not found. Install with: gem install ruby2d"
      exit(1)
    end

    set title: "Affine Transformations", width: 900, height: 700
    set background: "black"

    all_points = samples.flat_map { |(_, poly, _)| poly.points }
    min_x = all_points.map(&:x).min
    max_x = all_points.map(&:x).max
    min_y = all_points.map(&:y).min
    max_y = all_points.map(&:y).max

    pad = 60.0
    range_x = (max_x - min_x).abs
    range_y = (max_y - min_y).abs
    range_x = 1.0 if range_x.zero?
    range_y = 1.0 if range_y.zero?

    scale_x = (Window.width - 2 * pad) / range_x
    scale_y = (Window.height - 2 * pad) / range_y
    scale = [scale_x, scale_y].min

    to_screen = lambda do |p|
      sx = pad + (p.x - min_x) * scale
      sy = pad + (p.y - min_y) * scale
      [sx, Window.height - sy]
    end

    samples.each do |label, poly, color|
      # Draw polygon edges
      pts = poly.points.map { |p| to_screen.call(p) }
      pts.each_with_index do |(x1, y1), i|
        x2, y2 = pts[(i + 1) % pts.length]
        Line.new(x1: x1, y1: y1, x2: x2, y2: y2, width: 2, color: color)
        Circle.new(x: x1, y: y1, radius: 4, color: color)
      end
      # Label near the first point
      lx, ly = pts.first
      Text.new(label, x: lx + 6, y: ly + 6, size: 16, color: color)
    end

    show
  elsif ARGV.include?("--html")
    width = 320
    height = 260
    background = "#111111"
    grid_color = "#333333"
    pad = 40.0

    all_points = samples.flat_map { |(_, poly, _)| poly.points }
    min_x = all_points.map(&:x).min
    max_x = all_points.map(&:x).max
    min_y = all_points.map(&:y).min
    max_y = all_points.map(&:y).max

    range_x = (max_x - min_x).abs
    range_y = (max_y - min_y).abs
    range_x = 1.0 if range_x.zero?
    range_y = 1.0 if range_y.zero?

    scale_x = (width - 2 * pad) / range_x
    scale_y = (height - 2 * pad) / range_y
    scale = [scale_x, scale_y].min
    grid_size = scale

    to_screen = lambda do |p|
      sx = pad + (p.x - min_x) * scale
      sy = pad + (p.y - min_y) * scale
      [sx, height - sy]
    end

    def svg_polygon(poly, color, to_screen, id: nil, data_from: nil, data_to: nil)
      pts = poly.points.map { |p| to_screen.call(p).join(",") }
      point_str = pts.map { |x, y| "#{x},#{y}" }.join(" ")
      data_attr = ""
      data_attr += " data-from='#{data_from}'" if data_from
      data_attr += " data-to='#{data_to}'" if data_to
      id_attr = id ? " id=\"#{id}\"" : ""
      circles = pts.map.with_index do |(x, y), idx|
        "<circle class=\"vertex\" data-idx=\"#{idx}\" cx=\"#{x}\" cy=\"#{y}\" r=\"4\" fill=\"#{color}\" />"
      end.join("\n")
      <<~SVG
        <g>
          <polygon#{id_attr}#{data_attr} points="#{point_str}" fill="none" stroke="#{color}" stroke-width="2" />
          #{circles}
        </g>
      SVG
    end

    original_label, original_poly, _original_color = samples.first
    rows = samples.drop(1).each_with_index.map do |(label, poly, color), i|
      grid_id = "grid-#{i}"
      grid = <<~GRID
        <defs>
          <pattern id="#{grid_id}" width="#{grid_size}" height="#{grid_size}" patternUnits="userSpaceOnUse">
            <path d="M #{grid_size} 0 L 0 0 0 #{grid_size}" fill="none" stroke="#{grid_color}" stroke-width="1" />
          </pattern>
        </defs>
        <rect width="100%" height="100%" fill="url(##{grid_id})" />
      GRID

      left_svg = <<~SVG
        <svg viewBox="0 0 #{width} #{height}" width="#{width}" height="#{height}" xmlns="http://www.w3.org/2000/svg">
          #{grid}
          #{svg_polygon(original_poly, "#aaaaaa", to_screen)}
        </svg>
      SVG

      from_pts = original_poly.points.map { |p| to_screen.call(p) }
      to_pts = poly.points.map { |p| to_screen.call(p) }
      data_from = JSON.generate(from_pts)
      data_to = JSON.generate(to_pts)

      right_svg = <<~SVG
        <svg viewBox="0 0 #{width} #{height}" width="#{width}" height="#{height}" xmlns="http://www.w3.org/2000/svg">
          #{grid}
          #{svg_polygon(poly, color, to_screen, id: "poly-#{i}", data_from: data_from, data_to: data_to)}
        </svg>
      SVG

      <<~ROW
        <div class="row">
          <div class="cell">
            <div class="caption">#{original_label}</div>
            #{left_svg}
          </div>
          <div class="label">#{label}</div>
          <div class="cell">
            <div class="caption">Dönüşmüş Poligon</div>
            #{right_svg}
          </div>
        </div>
      ROW
    end.join("\n")

    # Normal transformation visual example (wrong vs inverse-transpose)
    p1 = Point.new(0, 0)
    p2 = Point.new(3, 1)
    tangent = [p2.x - p1.x, p2.y - p1.y]
    normal = perpendicular(tangent)
    m = [
      [1.5, 0.4],
      [0.0, 0.5]
    ]
    t_trans = mat_vec_mul(m, tangent)
    n_wrong = mat_vec_mul(m, normal)
    n_right = mat_vec_mul(mat_inverse_transpose(m), normal)

    normal_width = 320
    normal_height = 260
    normal_pad = 40.0
    normal_points = [
      [0, 0],
      tangent,
      normal,
      t_trans,
      n_wrong,
      n_right
    ]
    min_nx = normal_points.map { |v| v[0] }.min
    max_nx = normal_points.map { |v| v[0] }.max
    min_ny = normal_points.map { |v| v[1] }.min
    max_ny = normal_points.map { |v| v[1] }.max

    range_nx = (max_nx - min_nx).abs
    range_ny = (max_ny - min_ny).abs
    range_nx = 1.0 if range_nx.zero?
    range_ny = 1.0 if range_ny.zero?

    n_scale_x = (normal_width - 2 * normal_pad) / range_nx
    n_scale_y = (normal_height - 2 * normal_pad) / range_ny
    n_scale = [n_scale_x, n_scale_y].min

    normal_to_screen = lambda do |v|
      sx = normal_pad + (v[0] - min_nx) * n_scale
      sy = normal_pad + (v[1] - min_ny) * n_scale
      [sx, normal_height - sy]
    end

    def svg_line(from, to, color, label = nil, data_from: nil, data_to: nil)
      x1, y1 = from
      x2, y2 = to
      data_attr = ""
      data_attr += " data-from='#{data_from}'" if data_from
      data_attr += " data-to='#{data_to}'" if data_to
      label_tag = ""
      if label
        label_tag = "<text x=\"#{x2 + 4}\" y=\"#{y2 - 4}\" fill=\"#{color}\" font-size=\"12\">#{label}</text>"
      end
      <<~SVG
        <line x1="#{x1}" y1="#{y1}" x2="#{x2}" y2="#{y2}" stroke="#{color}" stroke-width="2"#{data_attr} />
        #{label_tag}
      SVG
    end

    normal_grid = <<~GRID
      <defs>
        <pattern id="grid-normal" width="#{grid_size}" height="#{grid_size}" patternUnits="userSpaceOnUse">
          <path d="M #{grid_size} 0 L 0 0 0 #{grid_size}" fill="none" stroke="#{grid_color}" stroke-width="1" />
        </pattern>
      </defs>
      <rect width="100%" height="100%" fill="url(#grid-normal)" />
    GRID

    o0 = normal_to_screen.call([0, 0])
    o_tan = normal_to_screen.call(tangent)
    o_norm = normal_to_screen.call(normal)
    t0 = normal_to_screen.call([0, 0])
    t_tan = normal_to_screen.call(t_trans)
    t_wrong = normal_to_screen.call(n_wrong)
    t_right = normal_to_screen.call(n_right)

    data_tan_from = JSON.generate(o_tan)
    data_tan_to = JSON.generate(t_tan)
    data_wrong_from = JSON.generate(o_norm)
    data_wrong_to = JSON.generate(t_wrong)
    data_right_from = JSON.generate(o_norm)
    data_right_to = JSON.generate(t_right)

    normal_row = <<~ROW
      <div class="row">
        <div class="cell">
          <div class="caption">Orijinal Tangent / Normal</div>
          <svg viewBox="0 0 #{normal_width} #{normal_height}" width="#{normal_width}" height="#{normal_height}" xmlns="http://www.w3.org/2000/svg">
            #{normal_grid}
            #{svg_line(o0, o_tan, "#00aaff", "t")}
            #{svg_line(o0, o_norm, "#aaaaaa", "n")}
          </svg>
        </div>
        <div class="label">Normal Dönüşümü (yanlış vs doğru)</div>
        <div class="cell">
          <div class="caption">Dönüşmüş (t, n)</div>
          <svg viewBox="0 0 #{normal_width} #{normal_height}" width="#{normal_width}" height="#{normal_height}" xmlns="http://www.w3.org/2000/svg">
            #{normal_grid}
            #{svg_line(t0, t_tan, "#00aaff", "M·t", data_from: data_tan_from, data_to: data_tan_to)}
            #{svg_line(t0, t_wrong, "#ff5555", "M·n (yanlış)", data_from: data_wrong_from, data_to: data_wrong_to)}
            #{svg_line(t0, t_right, "#55ff88", "(M^-1)^T·n", data_from: data_right_from, data_to: data_right_to)}
          </svg>
        </div>
      </div>
    ROW

    html = <<~HTML
      <!DOCTYPE html>
      <html lang="tr">
      <head>
        <meta charset="utf-8" />
        <title>Affine Transformations</title>
        <style>
          body { margin: 0; background: #{background}; color: #fff; font-family: Arial, sans-serif; }
          .wrapper { max-width: 1200px; margin: 20px auto 40px; padding: 0 16px; }
          .row { display: flex; align-items: center; gap: 16px; margin: 16px 0; }
          .cell { display: flex; flex-direction: column; align-items: center; gap: 6px; }
          .caption { font-size: 12px; color: #bbbbbb; }
          .label { flex: 0 0 260px; text-align: center; font-size: 14px; }
          svg { display: block; background: #{background}; border: 1px solid #222; }
        </style>
      </head>
      <body>
        <div class="wrapper">
          #{rows}
          #{normal_row}
        </div>
        <script>
          (function () {
            const duration = 2000;
            const polygons = Array.from(document.querySelectorAll("polygon[id^='poly-']"));
            const animLines = Array.from(document.querySelectorAll("line[data-from][data-to]"));

            const datasets = polygons.map((poly) => {
              const from = JSON.parse(poly.getAttribute("data-from"));
              const to = JSON.parse(poly.getAttribute("data-to"));
              const svg = poly.closest("svg");
              const circles = Array.from(svg.querySelectorAll(".vertex"));
              return { poly, from, to, circles };
            });

            function lerp(a, b, t) { return a + (b - a) * t; }

            function render(now) {
              const t = ((now / duration) % 1);
              const ease = 0.5 - 0.5 * Math.cos(2 * Math.PI * t);

              datasets.forEach(({ poly, from, to, circles }) => {
                const pts = from.map((p, idx) => [
                  lerp(p[0], to[idx][0], ease),
                  lerp(p[1], to[idx][1], ease)
                ]);
                poly.setAttribute("points", pts.map((p) => p.join(",")).join(" "));
                circles.forEach((c, idx) => {
                  c.setAttribute("cx", pts[idx][0]);
                  c.setAttribute("cy", pts[idx][1]);
                });
              });

              animLines.forEach((line) => {
                const from = JSON.parse(line.getAttribute("data-from"));
                const to = JSON.parse(line.getAttribute("data-to"));
                const x = lerp(from[0], to[0], ease);
                const y = lerp(from[1], to[1], ease);
                line.setAttribute("x2", x);
                line.setAttribute("y2", y);
              });

              requestAnimationFrame(render);
            }

            requestAnimationFrame(render);
          })();
        </script>
      </body>
      </html>
    HTML

    output_path = File.join(__dir__, "affine_view.html")
    File.write(output_path, html)
    puts "HTML çıktı yazıldı: #{output_path}"
    if ARGV.include?("--open")
      system("xdg-open", output_path)
    end
  else
    samples.each do |label, poly, _color|
      print_polygon(label, poly)
    end
  end
end
