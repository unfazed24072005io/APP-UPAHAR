
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/domain/models/chat_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/widgets/conversation_tabview.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/controllers/chat_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/no_internet_screen_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/not_loggedin_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/widgets/chat_item_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/widgets/inbox_shimmer_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/widgets/search_inbox_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/screens/dashboard_screen.dart';
import 'package:provider/provider.dart';


class InboxScreen extends StatefulWidget {
  final bool isBackButtonExist;
  const InboxScreen({super.key, this.isBackButtonExist = true});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> with SingleTickerProviderStateMixin{

  TextEditingController searchController = TextEditingController();
  late TabController _tabController;

  late bool isGuestMode;
  @override
  void initState() {

    isGuestMode = !Provider.of<AuthController>(context, listen: false).isLoggedIn();
      if(!isGuestMode) {
        load();
        _tabController = TabController(vsync: this, length: 2);
      }
    super.initState();
  }


  Future<void> load ()async {
    // await Provider.of<ChatController>(context, listen: false).getChatList(1, reload: false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(canPop: Navigator.of(context).canPop(),
      onPopInvoked: (val) async{
        if(Navigator.of(context).canPop()){
          return;
        }else{
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (BuildContext context) => const DashBoardScreen()));
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(title: getTranslated('inbox', context), isBackButtonExist: widget.isBackButtonExist,
        onBackPressed: (){
          if(Navigator.of(context).canPop()){
            Navigator.of(context).pop();
          }else{
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (BuildContext context) => const DashBoardScreen()));
          }
        }),
        body: Consumer<ChatController>(
          builder: (context, chat, _) {
            return Column(children: [
              if(!isGuestMode)
              Consumer<ChatController>(
                builder: (context, chat, _) {
                  return Padding(padding: const EdgeInsets.fromLTRB( Dimensions.homePagePadding,
                      Dimensions.paddingSizeSmall, Dimensions.homePagePadding, 0),
                    child: SearchInboxWidget(hintText: getTranslated('search', context)));
                }),

              if(!isGuestMode)
              Padding(padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeExtraSmall,
                Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall),
                child: ConversationListTabview(tabController: _tabController),
              ),

              Expanded(child: isGuestMode ? NotLoggedInWidget(message: getTranslated('to_communicate_with_vendors', context)) :

                RefreshIndicator(
                  onRefresh: () async {
                    searchController.clear();
                    await chat.getChatList(1, userType: _tabController.index);
                  },
                child: Consumer<ChatController>(
                  builder: (context, chatProvider, child) {
                    // ChatModel? _cahtModel = _tabController.index == 0 ?  chatProvider.isSearchComplete ?
                    // chatProvider.searchDeliverymanChatModel : chatProvider.deliverymanChatModel :
                    // chatProvider.isSearchComplete ? chatProvider.searchChatModel : chatProvider.chatModel;
                    ChatModel? cahtModel;

                    if(_tabController.index == 0){
                      if(chatProvider.isSearchComplete){
                        cahtModel = chatProvider.searchDeliverymanChatModel;
                      } else {
                        cahtModel = chatProvider.deliverymanChatModel;
                      }
                    } else{
                      if(chatProvider.isSearchComplete){
                        cahtModel = chatProvider.searchChatModel;
                      } else {
                        cahtModel = chatProvider.chatModel;
                      }
                    }

                    return cahtModel != null? (cahtModel.chat != null && cahtModel.chat!.isNotEmpty)?
                      ListView.builder(
                        itemCount: cahtModel.chat?.length,
                        padding: const EdgeInsets.all(0),
                        itemBuilder: (context, index) {
                          return ChatItemWidget(chat: cahtModel?.chat![index], chatProvider: chat);
                        },
                      ) : const NoInternetOrDataScreenWidget(isNoInternet: false, message: 'no_conversion', icon: Images.noInbox) : const InboxShimmerWidget();
                  }))
              ),
            ]);
          }
        ),
      ),
    );
  }
}



