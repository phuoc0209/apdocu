import 'package:flutter/material.dart';

typedef OnRate = void Function(double rating);

class RatingStars extends StatefulWidget {
  final double initial;
  final OnRate? onRate;

  const RatingStars({super.key, this.initial = 4.0, this.onRate});

  @override
  State<RatingStars> createState() => _RatingStarsState();
}

class _RatingStarsState extends State<RatingStars> {
  late double _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final idx = i + 1;
        final selected = _rating >= idx;
        return IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          icon: Icon(
            selected ? Icons.star : Icons.star_border,
            color: selected ? const Color(0xFFFFC107) : Colors.grey,
            size: 22,
          ),
          onPressed: () {
            setState(() => _rating = idx.toDouble());
            widget.onRate?.call(_rating);
          },
        );
      }),
    );
  }
}
