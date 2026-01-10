import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/theme/app_theme.dart';
import '../core/models/community_member.dart';
import '../core/services/community_service.dart';
import '../core/utils/toast_helper.dart';
import '../models/community.dart';

class CommunityMembersPage extends StatefulWidget {
  final Community community;

  const CommunityMembersPage({super.key, required this.community});

  @override
  State<CommunityMembersPage> createState() => _CommunityMembersPageState();
}

class _CommunityMembersPageState extends State<CommunityMembersPage> {
  final CommunityService _communityService = CommunityService();
  final TextEditingController _searchController = TextEditingController();

  List<CommunityMember> _allMembers = [];
  List<CommunityMember> _filteredMembers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterMembers();
    });
  }

  void _filterMembers() {
    _filteredMembers = _allMembers.where((member) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          member.displayName.toLowerCase().contains(_searchQuery);

      final matchesFilter =
          _selectedFilter == 'All' ||
          (_selectedFilter == 'Admins' &&
              (member.role == 'owner' || member.role == 'admin')) ||
          (_selectedFilter == 'Moderators' && member.role == 'moderator') ||
          (_selectedFilter == 'Members' && member.role == 'member');

      return matchesSearch && matchesFilter;
    }).toList();
  }

  Future<void> _loadMembers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final members = await _communityService.getCommunityMembers(
        widget.community.id,
        limit: 100,
      );

      setState(() {
        _allMembers = members;
        _filterMembers();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ToastHelper.error(context, 'Failed to load members: ${e.toString()}');
      }
    }
  }

  Future<void> _showMemberOptions(CommunityMember member) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Check if current user can manage members
    final currentUserMember = _allMembers.firstWhere(
      (m) => m.userId == currentUser.uid,
      orElse: () => CommunityMember(
        userId: '',
        displayName: '',
        profileImageUrl: '',
        role: 'member',
        joinedAt: DateTime.now(),
        isActive: false,
      ),
    );

    if (!currentUserMember.canManageMembers) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.secondaryBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.accentGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              member.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            if (member.role != 'owner') ...[
              ListTile(
                leading: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.blue,
                ),
                title: Text(
                  member.role == 'admin' ? 'Remove Admin' : 'Make Admin',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _updateMemberRole(
                    member,
                    member.role == 'admin' ? 'member' : 'admin',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.security, color: Colors.green),
                title: Text(
                  member.role == 'moderator'
                      ? 'Remove Moderator'
                      : 'Make Moderator',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _updateMemberRole(
                    member,
                    member.role == 'moderator' ? 'member' : 'moderator',
                  );
                },
              ),
              const Divider(color: Colors.white12),
              ListTile(
                leading: const Icon(Icons.person_remove, color: Colors.red),
                title: const Text(
                  'Remove from Community',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showRemoveMemberDialog(member);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _updateMemberRole(CommunityMember member, String newRole) async {
    try {
      await _communityService.updateMemberRole(
        widget.community.id,
        member.userId,
        newRole,
      );

      if (mounted) {
        ToastHelper.success(context, 'Member role updated successfully');
        _loadMembers(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.error(context, 'Failed to update member role');
      }
    }
  }

  void _showRemoveMemberDialog(CommunityMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: const Text(
          'Remove Member',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to remove ${member.displayName} from this community?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeMember(member);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _removeMember(CommunityMember member) async {
    try {
      await _communityService.removeMember(widget.community.id, member.userId);

      if (mounted) {
        ToastHelper.success(context, 'Member removed successfully');
        _loadMembers(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.error(context, 'Failed to remove member');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              _buildFilterChips(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.accentOrange,
                        ),
                      )
                    : _buildMembersList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.accentGray,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Members',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.community.name,
                  style: const TextStyle(
                    color: AppTheme.secondaryText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accentOrange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.accentOrange),
            ),
            child: Text(
              '${_allMembers.length}',
              style: const TextStyle(
                color: AppTheme.accentOrange,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search members...',
          hintStyle: const TextStyle(color: AppTheme.secondaryText),
          prefixIcon: const Icon(Icons.search, color: AppTheme.secondaryText),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: const Icon(Icons.clear, color: AppTheme.secondaryText),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Admins', 'Moderators', 'Members'];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
                _filterMembers();
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? AppTheme.primaryGradient : null,
                color: isSelected ? null : AppTheme.secondaryBlack,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.secondaryText,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMembersList() {
    if (_filteredMembers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.people_outline,
              size: 48,
              color: AppTheme.secondaryText,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? 'No members found' : 'No members yet',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try different search terms'
                  : 'Members will appear here when they join',
              style: const TextStyle(
                color: AppTheme.secondaryText,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredMembers.length,
      itemBuilder: (context, index) {
        final member = _filteredMembers[index];
        return _buildMemberCard(member);
      },
    );
  }

  Widget _buildMemberCard(CommunityMember member) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final canManage =
        currentUser != null &&
        _allMembers.any(
          (m) => m.userId == currentUser.uid && m.canManageMembers,
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // Profile Image
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _getRoleColor(member.role), width: 2),
            ),
            child: ClipOval(
              child: member.profileImageUrl.isNotEmpty
                  ? Image.network(
                      member.profileImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppTheme.accentGray,
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    )
                  : Container(
                      color: AppTheme.accentGray,
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          // Member Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        member.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getRoleColor(
                          member.role,
                        ).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getRoleColor(member.role)),
                      ),
                      child: Text(
                        member.roleDisplayName,
                        style: TextStyle(
                          color: _getRoleColor(member.role),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Joined ${_formatDate(member.joinedAt)}',
                  style: const TextStyle(
                    color: AppTheme.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Actions
          if (canManage && member.role != 'owner')
            IconButton(
              onPressed: () => _showMemberOptions(member),
              icon: const Icon(Icons.more_vert, color: AppTheme.secondaryText),
            ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'owner':
        return Colors.purple;
      case 'admin':
        return Colors.red;
      case 'moderator':
        return Colors.blue;
      case 'member':
      default:
        return AppTheme.accentOrange;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
