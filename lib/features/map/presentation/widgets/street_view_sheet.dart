import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/map_theme.dart';

class StreetViewSheet extends StatefulWidget {
  final double lat;
  final double lng;
  final VoidCallback onClose;

  const StreetViewSheet({
    Key? key,
    required this.lat,
    required this.lng,
    required this.onClose,
  }) : super(key: key);

  @override
  State<StreetViewSheet> createState() => _StreetViewSheetState();
}

class _StreetViewSheetState extends State<StreetViewSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _backdropAnim;
  late WebViewController _webViewController;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 380),
      vsync: this,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0, 0.6),
      ),
    );

    _backdropAnim = Tween<double>(begin: 0, end: 0.55).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _initializeWebView();
    _animationController.forward();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },
        ),
      )
      ..loadRequest(
        Uri.parse(
          'https://www.google.com/maps/embed/v1/streetview'
          '?key=AIzaSyAHaoJm9fWG3Dn_QOKHdN2E5CqxUKoE07k'
          '&location=${widget.lat},${widget.lng}'
          '&heading=210'
          '&pitch=10'
          '&fov=80'
          '&source=outdoor',
        ),
      );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleClose() {
    _animationController.reverse().then((_) {
      if (mounted) {
        widget.onClose();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Scrim backdrop
        AnimatedBuilder(
          animation: _backdropAnim,
          builder: (context, child) {
            return GestureDetector(
              onTap: _handleClose,
              child: Container(
                color: Colors.black.withOpacity(_backdropAnim.value),
              ),
            );
          },
        ),
        // Sheet with slide and fade animations
        SlideTransition(
          position: _slideAnim,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Container(
              decoration: BoxDecoration(
                color: MapTheme.surfaceColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: MapTheme.primaryOrange,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SheetHeader(onClose: _handleClose),
                      Expanded(
                        child: _WebViewBody(
                          webViewController: _webViewController,
                          isLoading: _isLoading,
                          hasError: _hasError,
                          lat: widget.lat,
                          lng: widget.lng,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final VoidCallback onClose;

  const _SheetHeader({
    Key? key,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle pill
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: MapTheme.textSecondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Orange badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: MapTheme.primaryOrange.withOpacity(0.15),
                  border: Border.all(
                    color: MapTheme.primaryOrange,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.360,
                      size: 16,
                      color: MapTheme.primaryOrange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Street View',
                      style: MapTheme.labelSmall.copyWith(
                        color: MapTheme.primaryOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Close button
              GestureDetector(
                onTap: onClose,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MapTheme.textSecondary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 20,
                    color: MapTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WebViewBody extends StatefulWidget {
  final WebViewController webViewController;
  final bool isLoading;
  final bool hasError;
  final double lat;
  final double lng;

  const _WebViewBody({
    Key? key,
    required this.webViewController,
    required this.isLoading,
    required this.hasError,
    required this.lat,
    required this.lng,
  }) : super(key: key);

  @override
  State<_WebViewBody> createState() => _WebViewBodyState();
}

class _WebViewBodyState extends State<_WebViewBody>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    if (widget.isLoading) {
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(_WebViewBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading != widget.isLoading) {
      if (widget.isLoading) {
        _shimmerController.repeat();
      } else {
        _shimmerController.stop();
      }
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hasError) {
      return _ErrorState(lat: widget.lat, lng: widget.lng);
    }

    return Stack(
      children: [
        WebViewWidget(controller: widget.webViewController),
        if (widget.isLoading)
          _LoadingShimmer(controller: _shimmerController),
      ],
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  final AnimationController controller;

  const _LoadingShimmer({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return AnimatedOpacity(
          opacity: (0.5 + 0.3 * (0.5 - (controller.value - 0.5).abs())).clamp(0, 1),
          duration: const Duration(milliseconds: 100),
          child: Container(
            color: MapTheme.surfaceColor,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      MapTheme.primaryOrange,
                    ),
                    strokeWidth: 2,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading Street View...',
                    style: MapTheme.bodySmall.copyWith(
                      color: MapTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  final double lat;
  final double lng;

  const _ErrorState({
    Key? key,
    required this.lat,
    required this.lng,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MapTheme.surfaceColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                size: 48,
                color: MapTheme.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No Street View Coverage',
                style: MapTheme.headlineSmall.copyWith(
                  color: MapTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Street View is not available at coordinates\n$lat, $lng',
                style: MapTheme.bodySmall.copyWith(
                  color: MapTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
