class OrbWisp {
  const OrbWisp(this.angle, this.radius, this.width, this.phase, this.speed);
  final double angle, radius, width, phase, speed;
}

class OrbParticle {
  const OrbParticle(
    this.dx,
    this.dy,
    this.phase,
    this.speed,
    this.size,
    this.gold, {
    this.orbit = false,
  });

  final double dx, dy, phase, speed, size;
  final bool gold;
  final bool orbit;
}
